package tw.gymproject.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import tw.gymproject.dto.renewal.RenewalOptionsResponse;
import tw.gymproject.entity.CoachCourse;
import tw.gymproject.entity.Course;
import tw.gymproject.entity.Member;
import tw.gymproject.entity.Membercourse;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.exception.ResourceNotFoundException;
import tw.gymproject.repository.CoachCourseRepository;
import tw.gymproject.repository.CourseRepository;
import tw.gymproject.repository.MemberCourseRepo;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

//確認原方案權限，整理可選課程、日期範圍及付款方式。只查資料，不新增續約。
@Service
public class RenewalOptionsService {

    private static final Logger log =
            LoggerFactory.getLogger(RenewalOptionsService.class);

    private static final ZoneId TAIPEI =
            ZoneId.of("Asia/Taipei");

    private final MemberCourseRepo memberCourseRepo;
    private final CoachCourseRepository coachCourseRepository;
    private final CourseRepository courseRepository;

    public RenewalOptionsService(
            MemberCourseRepo memberCourseRepo,
            CoachCourseRepository coachCourseRepository,
            CourseRepository courseRepository
    ) {
        this.memberCourseRepo = memberCourseRepo;
        this.coachCourseRepository = coachCourseRepository;
        this.courseRepository = courseRepository;
    }

    @Transactional(
            readOnly = true,
            isolation = Isolation.SERIALIZABLE
    )
    public RenewalOptionsResponse getOptions(
            Integer coachId,
            Integer memberCourseId
    ) {
        // 同一次請求固定使用同一個台北時間
        LocalDateTime asOfDateTime =
                LocalDateTime.now(TAIPEI);

        LocalDate today =
                asOfDateTime.toLocalDate();

        // 1. 檢查 ID
        if (coachId == null || coachId <= 0) {
            throw new IllegalStateException(
                    "登入教練 ID 不完整"
            );
        }

        if (memberCourseId == null || memberCourseId <= 0) {
            throw new BusinessException(
                    "memberCourseId 必須為正整數"
            );
        }

        // 2. 查原方案
        Membercourse source = memberCourseRepo
                .findOverviewById(memberCourseId)
                .orElseThrow(
                        () -> new ResourceNotFoundException(
                                "找不到指定方案"
                        )
                );

        // 3. 確認方案屬於登入教練
        if (!Objects.equals(
                source.getCoach().getCoachid(),
                coachId
        )) {
            throw new ForbiddenException(
                    "無權辦理其他教練方案的續約"
            );
        }

        validateSource(source, today);

        Member member = source.getMember();

        if (!"active".equals(member.getStatus())
                && !"inactive".equals(member.getStatus())) {
            log.error(
                    "會員狀態異常：memberId={}, status={}",
                    member.getMemberid(),
                    member.getStatus()
            );

            throw new IllegalStateException(
                    "會員狀態資料異常"
            );
        }

        // 4. 查登入教練的授課配對
        List<CoachCourse> assignments =
                coachCourseRepository.findById_Coachid(coachId);

        Set<Integer> assignedCourseIds = new HashSet<>();

        for (CoachCourse assignment : assignments) {
            if (assignment.getId() == null
                    || assignment.getId().getCourseid() == null) {
                throw new IllegalStateException(
                        "教練授課配對資料不完整"
                );
            }

            assignedCourseIds.add(
                    assignment.getId().getCourseid()
            );
        }

        // 5. 只保留有配對且啟用的課程
        // 課程已由 Repository 按 ID 升冪排序
        List<RenewalOptionsResponse.CourseOption> courses =
                new ArrayList<>();

        if (!assignedCourseIds.isEmpty()) {
            List<Course> activeCourses =
                    courseRepository.findByStatusOrderByCourseidAsc(
                            "active"
                    );

            for (Course course : activeCourses) {
                if (!assignedCourseIds.contains(
                        course.getCourseid()
                )) {
                    continue;
                }

                RenewalOptionsResponse.CourseOption option =
                        new RenewalOptionsResponse.CourseOption();

                option.setCourseId(course.getCourseid());
                option.setCourseName(course.getCoursename());

                courses.add(option);
            }
        }

        // 原課仍合法時才預選，不自動選其他課
        Integer sourceCourseId =
                source.getCourse().getCourseid();

        boolean sourceCourseAvailable = courses.stream()
                .anyMatch(option -> Objects.equals(
                        option.getCourseId(),
                        sourceCourseId
                ));

        // 6. 整理學員資料
        RenewalOptionsResponse.MemberInfo memberInfo =
                new RenewalOptionsResponse.MemberInfo();

        memberInfo.setMemberId(member.getMemberid());
        memberInfo.setName(member.getName());
        memberInfo.setStatus(member.getStatus());

        // 7. 整理原方案資料
        RenewalOptionsResponse.SourceCourse sourceCourse =
                new RenewalOptionsResponse.SourceCourse();

        sourceCourse.setCourseId(sourceCourseId);

        sourceCourse.setCourseName(
                source.getCourse().getCoursename()
        );

        sourceCourse.setPurchaseDate(source.getPurchasedate());
        sourceCourse.setTotalSessions(source.getTotalsessions());
        sourceCourse.setRemainingSessions(
                source.getRemainingsessions()
        );

        sourceCourse.setCoachId(
                source.getCoach().getCoachid()
        );

        sourceCourse.setCoachName(
                source.getCoach().getName()
        );

        // 8. 固定教練為登入教練
        RenewalOptionsResponse.CoachInfo coachInfo =
                new RenewalOptionsResponse.CoachInfo();

        coachInfo.setCoachId(coachId);
        coachInfo.setCoachName(
                source.getCoach().getName()
        );

        // 9. 組成回傳資料
        RenewalOptionsResponse response =
                new RenewalOptionsResponse();

        response.setMemberCourseId(memberCourseId);
        response.setAsOfDateTime(asOfDateTime);
        response.setToday(today);
        response.setMember(memberInfo);
        response.setSourceCourse(sourceCourse);
        response.setCoach(coachInfo);
        response.setCourses(courses);

        response.setDefaultCourseId(
                sourceCourseAvailable ? sourceCourseId : null
        );

        response.setDefaultPurchaseDate(today);
        response.setMinPurchaseDate(source.getPurchasedate());
        response.setMaxPurchaseDate(today);

        response.setPaymentMethods(
                List.of(
                        paymentOption("cash", "現金"),
                        paymentOption("transfer", "轉帳"),
                        paymentOption("card", "信用卡")
                )
        );

        // 10. 判斷表單是否可送出
        if ("inactive".equals(member.getStatus())) {
            response.setCanSubmit(false);

            response.setDisabledReason(
                    "此會員已停用，請先恢復會員後再辦理續約"
            );
        } else if (courses.isEmpty()) {
            response.setCanSubmit(false);

            response.setDisabledReason(
                    "目前沒有可辦理的課程"
            );
        } else {
            response.setCanSubmit(true);
            response.setDisabledReason(null);
        }

        return response;
    }

    // 不自動修正異常資料
    private void validateSource(
            Membercourse source,
            LocalDate today
    ) {
        Integer total = source.getTotalsessions();
        Integer remaining = source.getRemainingsessions();
        LocalDate purchaseDate = source.getPurchasedate();

        if (total == null
                || remaining == null
                || total <= 0
                || remaining < 0
                || remaining > total) {
            log.error(
                    "原方案堂數異常：memberCourseId={}, total={}, remaining={}",
                    source.getMembercourseid(),
                    total,
                    remaining
            );

            throw new IllegalStateException(
                    "原方案堂數資料異常"
            );
        }

        if (purchaseDate == null || purchaseDate.isAfter(today)) {
            log.error(
                    "原方案購課日期異常：memberCourseId={}, purchaseDate={}",
                    source.getMembercourseid(),
                    purchaseDate
            );

            throw new IllegalStateException(
                    "原方案購課日期資料異常"
            );
        }
    }

    private RenewalOptionsResponse.PaymentOption paymentOption(
            String value,
            String label
    ) {
        RenewalOptionsResponse.PaymentOption option =
                new RenewalOptionsResponse.PaymentOption();

        option.setValue(value);
        option.setLabel(label);

        return option;
    }
}