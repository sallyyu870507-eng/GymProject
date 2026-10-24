package tw.gymproject.service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;

import org.springframework.stereotype.Service;

import tw.gymproject.dto.renewal.RenewalCreateRequest;
import tw.gymproject.dto.renewal.RenewalCreateResponse;

import tw.gymproject.entity.CoachCourse;
import tw.gymproject.entity.CoachCourseId;
import tw.gymproject.entity.Course;
import tw.gymproject.entity.Member;
import tw.gymproject.entity.MemberCourse;
import tw.gymproject.entity.Renewal;

import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ConflictException;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.exception.ResourceNotFoundException;

import tw.gymproject.repository.CourseRepository;
import tw.gymproject.repository.MemberCourseRepo;
import tw.gymproject.repository.RenewalRepo;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Pattern;

@Service
public class RenewalCreateService {

    private static final ZoneId TAIPEI =
            ZoneId.of("Asia/Taipei");

    private static final Set<String> PAYMENT_METHODS =
            Set.of("cash", "transfer", "card");

    private static final Pattern DATE_PATTERN =
            Pattern.compile("^\\d{4}-\\d{2}-\\d{2}$");

    private final MemberCourseRepo memberCourseRepo;
    private final CourseRepository courseRepository;
    private final RenewalRepo renewalRepo;
    private final SubmissionGuardService submissionGuardService;
    private final EntityManager entityManager;

    public RenewalCreateService(
            MemberCourseRepo memberCourseRepo,
            CourseRepository courseRepository,
            RenewalRepo renewalRepo,
            SubmissionGuardService submissionGuardService,
            EntityManager entityManager
    ) {
        this.memberCourseRepo = memberCourseRepo;
        this.courseRepository = courseRepository;
        this.renewalRepo = renewalRepo;
        this.submissionGuardService = submissionGuardService;
        this.entityManager = entityManager;
    }

    /*
     * 不加 @Transactional。
     * 真正新增的交易由 SubmissionGuardService 統一管理。
     *
     * accountId、coachId 必須來自後端登入資料。
     */
    public SubmissionGuardService.SubmissionResult createRenewal(
            Integer coachId,
            Integer accountId,
            Integer sourceMemberCourseId,
            String idempotencyKey,
            RenewalCreateRequest request
    ) {
        requireAuthorizedSource(
                coachId,
                accountId,
                sourceMemberCourseId
        );

        NormalizedRequest normalized =
                normalizeRequest(request);

        String requestPath =
                "/api/coach/renewal/"
                        + sourceMemberCourseId
                        + "/renewals";

        return submissionGuardService.execute(
                accountId,
                requestPath,
                idempotencyKey,
                normalized,

                // 重送既有成功結果前，也要重新驗證方案授權。
                () -> {
                    requireAuthorizedSource(
                            coachId,
                            accountId,
                            sourceMemberCourseId
                    );
                },

                // 只有第一次執行才會進入真正的購課流程。
                () -> insertRenewal(
                        coachId,
                        accountId,
                        sourceMemberCourseId,
                        normalized
                )
        );
    }

    private RenewalCreateResponse insertRenewal(
            Integer coachId,
            Integer accountId,
            Integer sourceMemberCourseId,
            NormalizedRequest request
    ) {
        MemberCourse source = requireAuthorizedSource(
                coachId,
                accountId,
                sourceMemberCourseId
        );

        /*
         * 重新讀取並鎖定來源方案。
         * 交易完成前，避免來源方案被同時修改或刪除。
         */
        entityManager.refresh(
                source,
                LockModeType.PESSIMISTIC_WRITE
        );

        // 鎖定後重新確認擁有權。
        validateOwnership(source, coachId, accountId);

        LocalDateTime now = LocalDateTime.now(TAIPEI);
        LocalDate today = now.toLocalDate();

        validateSource(source, today);

        if (request.purchaseDate()
                .isBefore(source.getPurchasedate())) {
            throw new BusinessException(
                    "purchaseDate 不可早於原方案購課日期"
            );
        }

        if (request.purchaseDate().isAfter(today)) {
            throw new BusinessException(
                    "purchaseDate 不可晚於今天"
            );
        }

        /*
         * 在交易內鎖定並重新讀取會員。
         * 會員若已停用，這次新操作必須拒絕。
         */
        Member member = source.getMember();

        entityManager.refresh(
                member,
                LockModeType.PESSIMISTIC_WRITE
        );

        String memberStatus = cleanStatus(member.getStatus());

        if ("inactive".equals(memberStatus)) {
            throw new ConflictException(
                    "此會員已停用，請先恢復會員後再辦理續約"
            );
        }

        if (!"active".equals(memberStatus)) {
            throw new ConflictException(
                    "目前會員狀態不允許辦理續約"
            );
        }

        /*
         * 查詢所選課程，不只相信 P1 初始化時的選項。
         */
        Course course = courseRepository
                .findById(request.courseId())
                .orElseThrow(
                        () -> new ConflictException(
                                "所選課程已不存在，請重新載入課程選項"
                        )
                );

        entityManager.refresh(
                course,
                LockModeType.PESSIMISTIC_WRITE
        );

        if (!"active".equals(cleanStatus(course.getStatus()))) {
            throw new ConflictException(
                    "所選課程已停用，請重新選擇課程"
            );
        }

        /*
         * 用複合主鍵確認授課配對。
         * 不依賴 CoachCourse 是否有 coach/course 關聯欄位，
         * 可相容目前兩種 Entity 寫法。
         */
        CoachCourseId assignmentId = new CoachCourseId();
        assignmentId.setCoachid(coachId);
        assignmentId.setCourseid(request.courseId());

        CoachCourse assignment = entityManager.find(
                CoachCourse.class,
                assignmentId,
                LockModeType.PESSIMISTIC_READ
        );

        if (assignment == null) {
            throw new BusinessException(
                    "目前教練不可教授所選課程"
            );
        }

        // 第一筆寫入：建立新方案。
        MemberCourse newPlan = new MemberCourse();

        newPlan.setMember(member);
        newPlan.setCoach(source.getCoach());
        newPlan.setCourse(course);

        newPlan.setPurchasedate(request.purchaseDate());
        newPlan.setTotalsessions(request.addedSessions());
        newPlan.setRemainingsessions(request.addedSessions());
        newPlan.setStatus("active");

        MemberCourse savedPlan =
                memberCourseRepo.saveAndFlush(newPlan);

        // 第二筆寫入：建立原方案與新方案的續約關係。
        Renewal renewal = new Renewal();

        renewal.setMemberCourse(source);
        renewal.setNewMemberCourse(savedPlan);
        renewal.setRenewaldate(now);

        renewal.setAddedsessions(request.addedSessions());
        renewal.setAmount(request.amount());
        renewal.setPaymentmethod(request.paymentMethod());
        renewal.setNote(request.note());

        Renewal savedRenewal =
                renewalRepo.saveAndFlush(renewal);

        /*
         * 讀取資料庫實際保存的日期時間與數值。
         * 兩次 flush 都還在同一筆交易內，尚未獨立提交。
         */
        entityManager.refresh(savedPlan);
        entityManager.refresh(savedRenewal);

        return toResponse(
                source,
                savedPlan,
                savedRenewal
        );
    }

    private MemberCourse requireAuthorizedSource(
            Integer coachId,
            Integer accountId,
            Integer memberCourseId
    ) {
        if (memberCourseId == null || memberCourseId <= 0) {
            throw new BusinessException(
                    "memberCourseId 必須為正整數"
            );
        }

        if (coachId == null || accountId == null) {
            throw new ForbiddenException(
                    "登入教練資料不完整"
            );
        }

        MemberCourse source = memberCourseRepo
                .findOverviewById(memberCourseId)
                .orElseThrow(
                        () -> new ResourceNotFoundException(
                                "找不到指定方案"
                        )
                );

        validateOwnership(source, coachId, accountId);

        return source;
    }

    private void validateOwnership(
            MemberCourse source,
            Integer coachId,
            Integer accountId
    ) {
        if (!Objects.equals(
                source.getCoach().getCoachid(),
                coachId
        )) {
            throw new ForbiddenException(
                    "無權操作其他教練的方案"
            );
        }

        if (source.getCoach().getAccount() == null
                || !Objects.equals(
                source.getCoach()
                        .getAccount()
                        .getAccountid(),
                accountId
        )) {
            throw new ForbiddenException(
                    "登入帳號與教練資料不一致"
            );
        }
    }

    private void validateSource(
            MemberCourse source,
            LocalDate today
    ) {
        String status = cleanStatus(source.getStatus());

        if (!"active".equals(status)
                && !"usedup".equals(status)) {
            throw new ConflictException(
                    "目前來源方案狀態不允許辦理續約"
            );
        }

        Integer total = source.getTotalsessions();
        Integer remaining = source.getRemainingsessions();

        if (total == null
                || total <= 0
                || remaining == null
                || remaining < 0
                || remaining > total) {
            throw new ConflictException(
                    "來源方案堂數資料異常，請先確認資料"
            );
        }

        if (source.getPurchasedate() == null
                || source.getPurchasedate().isAfter(today)) {
            throw new ConflictException(
                    "來源方案購課日期異常，請先確認資料"
            );
        }
    }

    private NormalizedRequest normalizeRequest(
            RenewalCreateRequest request
    ) {
        if (request == null) {
            throw new BusinessException(
                    "續約資料不可為空"
            );
        }

        if (request.getCourseId() == null
                || request.getCourseId() <= 0) {
            throw new BusinessException(
                    "courseId 必須為正整數"
            );
        }

        if (request.getAddedSessions() == null
                || request.getAddedSessions() <= 0) {
            throw new BusinessException(
                    "addedSessions 必須為大於 0 的整數"
            );
        }

        if (request.getAmount() == null
                || request.getAmount() < 0) {
            throw new BusinessException(
                    "amount 必須為大於或等於 0 的整數"
            );
        }

        String paymentMethod = request.getPaymentMethod();

        if (paymentMethod == null
                || !PAYMENT_METHODS.contains(paymentMethod)) {
            throw new BusinessException(
                    "paymentMethod 必須為 cash、transfer 或 card"
            );
        }

        LocalDate purchaseDate =
                parsePurchaseDate(request.getPurchaseDate());

        String note = normalizeNote(request.getNote());

        return new NormalizedRequest(
                request.getCourseId(),
                request.getAddedSessions(),
                request.getAmount(),
                paymentMethod,
                purchaseDate,
                note
        );
    }

    private LocalDate parsePurchaseDate(String value) {
        if (value == null || value.isBlank()) {
            throw new BusinessException(
                    "purchaseDate 為必填"
            );
        }

        if (!DATE_PATTERN.matcher(value).matches()) {
            throw new BusinessException(
                    "purchaseDate 格式必須為 yyyy-MM-dd"
            );
        }

        LocalDate parsed;

        try {
            parsed = LocalDate.parse(
                    value,
                    DateTimeFormatter.ISO_LOCAL_DATE
            );

        } catch (DateTimeParseException ex) {
            throw new BusinessException(
                    "purchaseDate 不是有效的日期"
            );
        }

        if (parsed.getYear() < 1 || parsed.getYear() > 9999) {
            throw new BusinessException(
                    "purchaseDate 超出資料庫可儲存範圍"
            );
        }

        return parsed;
    }

    private String normalizeNote(String value) {
        if (value == null) {
            return null;
        }

        String normalized = value.strip();

        if (normalized.isBlank()) {
            return null;
        }

        if (normalized.length() > 500) {
            throw new BusinessException(
                    "note 不可超過 500 個 UTF-16 單位"
            );
        }

        return normalized;
    }

    private String cleanStatus(String value) {
        return value == null ? null : value.strip();
    }

    private RenewalCreateResponse toResponse(
            MemberCourse source,
            MemberCourse newPlan,
            Renewal renewal
    ) {
        RenewalCreateResponse response =
                new RenewalCreateResponse();

        response.setRenewalId(renewal.getRenewalid());

        response.setSourceMemberCourseId(
                source.getMembercourseid()
        );

        response.setNewMemberCourseId(
                newPlan.getMembercourseid()
        );

        response.setMemberId(
                newPlan.getMember().getMemberid()
        );

        response.setCourseId(
                newPlan.getCourse().getCourseid()
        );

        response.setCourseName(
                newPlan.getCourse().getCoursename()
        );

        response.setCoachId(
                newPlan.getCoach().getCoachid()
        );

        response.setCoachName(
                newPlan.getCoach().getName()
        );

        response.setPurchaseDate(newPlan.getPurchasedate());
        response.setRenewalDate(renewal.getRenewaldate());

        response.setAddedSessions(renewal.getAddedsessions());
        response.setTotalSessions(newPlan.getTotalsessions());

        response.setRemainingSessions(
                newPlan.getRemainingsessions()
        );

        response.setStatus(newPlan.getStatus());

        response.setAmount(renewal.getAmount());
        response.setPaymentMethod(renewal.getPaymentmethod());
        response.setNote(renewal.getNote());

        return response;
    }

    private record NormalizedRequest(
            Integer courseId,
            Integer addedSessions,
            Integer amount,
            String paymentMethod,
            LocalDate purchaseDate,
            String note
    ) {
    }
}
