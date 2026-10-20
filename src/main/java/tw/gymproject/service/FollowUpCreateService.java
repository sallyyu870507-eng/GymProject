package tw.gymproject.service;

import jakarta.persistence.EntityManager;

import org.springframework.stereotype.Service;

import tw.gymproject.dto.renewal.FollowUpCreateRequest;
import tw.gymproject.dto.renewal.FollowUpResponse;
import tw.gymproject.entity.FollowUp;
import tw.gymproject.entity.MemberCourse;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.exception.ResourceNotFoundException;
import tw.gymproject.repository.FollowUpRepo;
import tw.gymproject.repository.MemberCourseRepo;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Pattern;

@Service
public class FollowUpCreateService {

    private static final ZoneId TAIPEI =
            ZoneId.of("Asia/Taipei");

    private static final Set<String> CONTACT_METHODS =
            Set.of(
                    "PHONE",
                    "MESSAGE",
                    "IN_PERSON",
                    "OTHER"
            );

    private static final Set<String> FOLLOWUP_STATUSES =
            Set.of(
                    "NO_RESPONSE",
                    "CONSIDERING",
                    "AGREED",
                    "DECLINED"
            );

    // 完整當地日期時間，必須包含秒數。
    // 可以有 1～9 位小數秒，不接受 Z 或時區偏移。
    private static final Pattern LOCAL_DATE_TIME_PATTERN =
            Pattern.compile(
                    "^\\d{4}-\\d{2}-\\d{2}"
                            + "T\\d{2}:\\d{2}:\\d{2}"
                            + "(?:\\.\\d{1,9})?$"
            );

    private final MemberCourseRepo memberCourseRepo;
    private final FollowUpRepo followUpRepo;
    private final SubmissionGuardService submissionGuardService;
    private final EntityManager entityManager;

    public FollowUpCreateService(
            MemberCourseRepo memberCourseRepo,
            FollowUpRepo followUpRepo,
            SubmissionGuardService submissionGuardService,
            EntityManager entityManager
    ) {
        this.memberCourseRepo = memberCourseRepo;
        this.followUpRepo = followUpRepo;
        this.submissionGuardService = submissionGuardService;
        this.entityManager = entityManager;
    }

    /*
     * 此方法不要加 @Transactional。
     * SubmissionGuardService 會包住真正的新增交易。
     *
     * coachId、accountId 均須由後端登入資料取得。
     */
    public SubmissionGuardService.SubmissionResult createFollowUp(
            Integer coachId,
            Integer accountId,
            Integer memberCourseId,
            String idempotencyKey,
            FollowUpCreateRequest request
    ) {
        // 先檢查方案與登入帳號的對應關係。
        requireAuthorizedPlan(
                coachId,
                accountId,
                memberCourseId
        );

        LocalDateTime now = LocalDateTime.now(TAIPEI);

        NormalizedRequest normalized =
                normalizeRequest(request, now);

        // 使用後端組合的標準路徑作為提交保護範圍。
        String requestPath =
                "/api/renewal/"
                        + memberCourseId
                        + "/followups";

        return submissionGuardService.execute(
                accountId,
                requestPath,
                idempotencyKey,
                normalized,

                // 即使回傳快取結果，仍須檢查方案權限。
                () -> {
                    requireAuthorizedPlan(
                            coachId,
                            accountId,
                            memberCourseId
                    );
                },

                // 此區塊由 SubmissionGuardService 放入交易。
                () -> insertFollowUp(
                        coachId,
                        accountId,
                        memberCourseId,
                        normalized
                )
        );
    }

    private FollowUpResponse insertFollowUp(
            Integer coachId,
            Integer accountId,
            Integer memberCourseId,
            NormalizedRequest request
    ) {
        MemberCourse plan = requireAuthorizedPlan(
                coachId,
                accountId,
                memberCourseId
        );

        FollowUp followUp = new FollowUp();

        followUp.setMemberCourse(plan);
        followUp.setCoach(plan.getCoach());

        followUp.setCreatedate(request.createdDate());
        followUp.setContactmethod(request.contactMethod());
        followUp.setStatus(request.status());
        followUp.setNote(request.note());

        FollowUp saved = followUpRepo.saveAndFlush(followUp);

        /*
         * 重新讀取實際儲存結果。
         * 回傳並暫存的是資料庫保存後的值。
         */
        entityManager.refresh(saved);

        return toResponse(saved);
    }

    private MemberCourse requireAuthorizedPlan(
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

        MemberCourse plan = memberCourseRepo
                .findOverviewById(memberCourseId)
                .orElseThrow(
                        () -> new ResourceNotFoundException(
                                "找不到指定方案"
                        )
                );

        if (!Objects.equals(
                plan.getCoach().getCoachid(),
                coachId
        )) {
            throw new ForbiddenException(
                    "無權操作其他教練的方案"
            );
        }

        // 防止內部呼叫誤配教練 ID 與帳號 ID。
        if (plan.getCoach().getAccount() == null
                || !Objects.equals(
                plan.getCoach()
                        .getAccount()
                        .getAccountid(),
                accountId
        )) {
            throw new ForbiddenException(
                    "登入帳號與教練資料不一致"
            );
        }

        /*
         * 停用會員仍可新增關懷。
         * 因此這裡不要求 member.status = active。
         */
        return plan;
    }

    private NormalizedRequest normalizeRequest(
            FollowUpCreateRequest request,
            LocalDateTime now
    ) {
        if (request == null) {
            throw new BusinessException(
                    "新增關懷資料不可為空"
            );
        }

        LocalDateTime inputTime =
                parseCreatedDate(request.getCreatedDate());

        /*
         * 必須先檢查原始時間是否在未來，
         * 再把秒與小數秒歸零。
         */
        if (inputTime.isAfter(now)) {
            throw new BusinessException(
                    "聯繫時間不能晚於現在"
            );
        }

        String contactMethod = request.getContactMethod();

        if (contactMethod == null
                || !CONTACT_METHODS.contains(contactMethod)) {
            throw new BusinessException(
                    "contactMethod 必須為 "
                            + "PHONE、MESSAGE、IN_PERSON 或 OTHER"
            );
        }

        String status = request.getStatus();

        if (status == null
                || !FOLLOWUP_STATUSES.contains(status)) {
            throw new BusinessException(
                    "status 必須為 "
                            + "NO_RESPONSE、CONSIDERING、AGREED 或 DECLINED"
            );
        }

        String note = normalizeNote(request.getNote());

        return new NormalizedRequest(
                inputTime.truncatedTo(ChronoUnit.MINUTES),
                contactMethod,
                status,
                note
        );
    }

    private LocalDateTime parseCreatedDate(String value) {
        if (value == null || value.isBlank()) {
            throw new BusinessException(
                    "createdDate 為必填"
            );
        }

        if (!LOCAL_DATE_TIME_PATTERN.matcher(value).matches()) {
            throw new BusinessException(
                    "createdDate 必須為完整當地日期時間，"
                            + "格式例如 2026-10-19T10:00:00，"
                            + "不可包含時區"
            );
        }

        LocalDateTime parsed;

        try {
            parsed = LocalDateTime.parse(
                    value,
                    DateTimeFormatter.ISO_LOCAL_DATE_TIME
            );

        } catch (DateTimeParseException ex) {
            throw new BusinessException(
                    "createdDate 不是有效的日期時間"
            );
        }

        // 配合目前 followup.createdate 的 SQL Server DATETIME。
        if (parsed.getYear() < 1753
                || parsed.getYear() > 9999) {
            throw new BusinessException(
                    "createdDate 超出資料庫可儲存範圍"
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

        // String.length() 計算 UTF-16 單位。
        if (normalized.length() > 500) {
            throw new BusinessException(
                    "note 不可超過 500 個 UTF-16 單位"
            );
        }

        return normalized;
    }

    private FollowUpResponse toResponse(FollowUp followUp) {
        FollowUpResponse response = new FollowUpResponse();

        response.setFollowupId(followUp.getFollowupid());

        response.setMemberCourseId(
                followUp.getMemberCourse().getMembercourseid()
        );

        response.setCreatedDate(followUp.getCreatedate());

        response.setCoachId(
                followUp.getCoach().getCoachid()
        );

        response.setCoachName(
                followUp.getCoach().getName()
        );

        response.setContactMethod(
                followUp.getContactmethod()
        );

        response.setStatus(followUp.getStatus());
        response.setNote(followUp.getNote());

        return response;
    }

    /*
     * 固定欄位的不可變資料，
     * 同時用於內容摘要與實際新增，
     * 避免檢查的內容和儲存的內容不同。
     */
    private record NormalizedRequest(
            LocalDateTime createdDate,
            String contactMethod,
            String status,
            String note
    ) {
    }
}