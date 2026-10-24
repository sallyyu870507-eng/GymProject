package tw.gymproject.service;

//確認方案權限，查詢相關紀錄，再整理成方案詳情 DTO
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import tw.gymproject.dto.renewal.RenewalOverviewResponse;
import tw.gymproject.dto.renewal.RenewalWorkbenchResponse;
import tw.gymproject.entity.FollowUp;
import tw.gymproject.entity.Member;
import tw.gymproject.entity.Membercourse;
import tw.gymproject.entity.Renewal;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.exception.ResourceNotFoundException;
import tw.gymproject.repository.AttendanceRepo;
import tw.gymproject.repository.FollowUpRepo;
import tw.gymproject.repository.MemberCourseRepo;
import tw.gymproject.repository.RenewalRepo;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

@Service
public class RenewalOverviewService {

    private static final Logger log =
            LoggerFactory.getLogger(RenewalOverviewService.class);

    private static final ZoneId TAIPEI =
            ZoneId.of("Asia/Taipei");

    private final MemberCourseRepo memberCourseRepo;
    private final AttendanceRepo attendanceRepo;
    private final FollowUpRepo followUpRepo;
    private final RenewalRepo renewalRepo;

    public RenewalOverviewService(
            MemberCourseRepo memberCourseRepo,
            AttendanceRepo attendanceRepo,
            FollowUpRepo followUpRepo,
            RenewalRepo renewalRepo
    ) {
        this.memberCourseRepo = memberCourseRepo;
        this.attendanceRepo = attendanceRepo;
        this.followUpRepo = followUpRepo;
        this.renewalRepo = renewalRepo;
    }

    @Transactional(
            readOnly = true,
            isolation = Isolation.SERIALIZABLE
    )
    public RenewalOverviewResponse getOverview(
            Integer coachId,
            Integer memberCourseId
    ) {
        // 1. 檢查參數
        if (memberCourseId == null || memberCourseId <= 0) {
            throw new BusinessException(
                    "memberCourseId 必須為正整數"
            );
        }

        if (coachId == null || coachId <= 0) {
            throw new IllegalStateException(
                    "登入教練 ID 不完整"
            );
        }

        // 同一次請求使用同一個台北時間
        LocalDateTime asOfDateTime =
                LocalDateTime.now(TAIPEI);

        LocalDate asOfDate =
                asOfDateTime.toLocalDate();

        // 2. 查方案
        Membercourse plan = memberCourseRepo
                .findOverviewById(memberCourseId)
                .orElseThrow(
                        () -> new ResourceNotFoundException(
                                "找不到指定方案"
                        )
                );

        // 3. 先驗證權限，再讀取及回傳詳情
        if (!Objects.equals(
                plan.getCoach().getCoachid(),
                coachId
        )) {
            throw new ForbiddenException(
                    "無權查看其他教練的方案"
            );
        }

        validateSessions(plan);

        Member member = plan.getMember();

        // 4. 查同組方案的活動基準
        RenewalWorkbenchResponse.CourseActivity activity =
                buildCourseActivity(plan, coachId, asOfDate);

        // 5. 查這個方案全部續約關聯
        List<RenewalWorkbenchResponse.OutgoingRenewal>
                outgoingRenewals =
                findOutgoingRenewals(coachId, memberCourseId);

        boolean hasRenewed =
                !outgoingRenewals.isEmpty();

        // 6. 依堂數、活動基準與續約紀錄分類
        List<String> tags = buildTags(
                plan.getRemainingsessions(),
                hasRenewed,
                activity.getDaysSinceBaseline()
        );

        // 7. 查最新關懷狀態
        FollowUp latestFollowup = followUpRepo
                .findLatestForCoachPlans(coachId)
                .stream()
                .filter(f -> Objects.equals(
                        f.getMemberCourse().getMembercourseid(),
                        memberCourseId
                ))
                .findFirst()
                .orElse(null);

        // 8. 組成回傳 DTO
        RenewalOverviewResponse response =
                new RenewalOverviewResponse();

        response.setAsOfDate(asOfDate);
        response.setAsOfDateTime(asOfDateTime);
        response.setMemberCourseId(memberCourseId);

        response.setMember(
                buildMemberInfo(member, asOfDate)
        );

        response.setCourse(
                buildCourseInfo(plan)
        );

        response.setCourseActivity(activity);
        response.setTags(tags);
        response.setHasRenewed(hasRenewed);
        response.setOutgoingRenewals(outgoingRenewals);

        // 有紀錄時保留原狀態，包括 null 或未知歷史值
        response.setFollowupStatus(
                latestFollowup == null
                        ? "NOT_CONTACTED"
                        : latestFollowup.getStatus()
        );

        response.setReminders(
                buildReminders(
                        plan.getRemainingsessions(),
                        hasRenewed,
                        tags,
                        activity.getDaysSinceBaseline()
                )
        );

        response.setActions(
                buildActions(member)
        );

        return response;
    }

    // 堂數異常屬於資料完整性問題，不自動修正
    private void validateSessions(Membercourse plan) {
        Integer total = plan.getTotalsessions();
        Integer remaining = plan.getRemainingsessions();

        if (total == null
                || remaining == null
                || total <= 0
                || remaining < 0
                || remaining > total) {

            log.error(
                    "方案堂數異常：memberCourseId={}, total={}, remaining={}",
                    plan.getMembercourseid(),
                    total,
                    remaining
            );

            throw new IllegalStateException(
                    "方案堂數資料異常"
            );
        }
    }

    private RenewalOverviewResponse.MemberInfo buildMemberInfo(
            Member member,
            LocalDate asOfDate
    ) {
        RenewalOverviewResponse.MemberInfo info =
                new RenewalOverviewResponse.MemberInfo();

        info.setMemberId(member.getMemberid());
        info.setName(member.getName());
        info.setAvatarUrl(member.getAvatarurl());
        info.setGender(member.getGender());
        info.setPhone(emptyToNull(member.getPhone()));
        info.setEmail(emptyToNull(member.getEmail()));
        info.setStatus(member.getStatus());

        LocalDate birthday = member.getBirthday();

        if (birthday == null) {
            info.setAge(null);
        } else if (birthday.isAfter(asOfDate)) {
            log.error(
                    "會員生日晚於今天：memberId={}, birthday={}",
                    member.getMemberid(),
                    birthday
            );

            throw new IllegalStateException(
                    "會員生日資料異常"
            );
        } else {
            info.setAge(
                    Period.between(birthday, asOfDate).getYears()
            );
        }

        return info;
    }

    private RenewalOverviewResponse.CourseInfo buildCourseInfo(
            Membercourse plan
    ) {
        RenewalOverviewResponse.CourseInfo info =
                new RenewalOverviewResponse.CourseInfo();

        info.setCourseId(
                plan.getCourse().getCourseid()
        );

        info.setCourseName(
                plan.getCourse().getCoursename()
        );

        info.setCoachId(
                plan.getCoach().getCoachid()
        );

        info.setCoachName(
                plan.getCoach().getName()
        );

        info.setPurchaseDate(plan.getPurchasedate());
        info.setTotalSessions(plan.getTotalsessions());
        info.setRemainingSessions(plan.getRemainingsessions());

        info.setUsedSessions(
                plan.getTotalsessions()
                        - plan.getRemainingsessions()
        );

        info.setStatus(plan.getStatus());

        return info;
    }

    private RenewalWorkbenchResponse.CourseActivity
    buildCourseActivity(
            Membercourse plan,
            Integer coachId,
            LocalDate asOfDate
    ) {
        Integer memberId =
                plan.getMember().getMemberid();

        Integer courseId =
                plan.getCourse().getCourseid();

        // 同學員＋同課程＋同教練，最後有效上課日
        LocalDate lastPresentDate = attendanceRepo
                .findCourseLastPresentDates(coachId, asOfDate)
                .stream()
                .filter(row ->
                        Objects.equals(row.getMemberId(), memberId)
                                && Objects.equals(
                                row.getCourseId(), courseId
                        )
                                && Objects.equals(
                                row.getCoachId(), coachId
                        )
                )
                .map(AttendanceRepo.CourseLastPresent::getLastPresentDate)
                .filter(Objects::nonNull)
                .findFirst()
                .orElse(null);

        RenewalWorkbenchResponse.CourseActivity activity =
                new RenewalWorkbenchResponse.CourseActivity();

        activity.setLastPresentDate(lastPresentDate);

        if (lastPresentDate != null) {
            long days = ChronoUnit.DAYS.between(
                    lastPresentDate,
                    asOfDate
            );

            activity.setDaysSinceLastPresent(days);
            activity.setBaselineType("LAST_PRESENT");
            activity.setBaselineDate(lastPresentDate);
            activity.setDaysSinceBaseline(days);

            return activity;
        }

        // 沒有有效出席，改用同組最早購課日
        LocalDate firstPurchaseDate = memberCourseRepo
                .findCourseFirstPurchaseDates(coachId, asOfDate)
                .stream()
                .filter(row ->
                        Objects.equals(row.getMemberId(), memberId)
                                && Objects.equals(
                                row.getCourseId(), courseId
                        )
                                && Objects.equals(
                                row.getCoachId(), coachId
                        )
                )
                .map(MemberCourseRepo.CourseFirstPurchase::getFirstPurchaseDate)
                .filter(Objects::nonNull)
                .findFirst()
                .orElse(null);

        activity.setDaysSinceLastPresent(null);

        if (firstPurchaseDate != null) {
            activity.setBaselineType("FIRST_PURCHASE");
            activity.setBaselineDate(firstPurchaseDate);

            activity.setDaysSinceBaseline(
                    ChronoUnit.DAYS.between(
                            firstPurchaseDate,
                            asOfDate
                    )
            );
        } else {
            activity.setBaselineType(null);
            activity.setBaselineDate(null);
            activity.setDaysSinceBaseline(null);

            log.warn(
                    "方案缺少合法活動基準：memberCourseId={}, "
                            + "memberId={}, courseId={}, coachId={}",
                    plan.getMembercourseid(),
                    memberId,
                    courseId,
                    coachId
            );
        }

        return activity;
    }

    private List<RenewalWorkbenchResponse.OutgoingRenewal>
    findOutgoingRenewals(
            Integer coachId,
            Integer memberCourseId
    ) {
        List<RenewalWorkbenchResponse.OutgoingRenewal> result =
                new ArrayList<>();

        // Repository 已依續約時間 DESC、ID DESC 排序
        for (Renewal renewal :
                renewalRepo.findWorkbenchRenewals(coachId)) {

            if (!Objects.equals(
                    renewal.getMemberCourse().getMembercourseid(),
                    memberCourseId
            )) {
                continue;
            }

            Membercourse target =
                    renewal.getNewMemberCourse();

            RenewalWorkbenchResponse.OutgoingRenewal item =
                    new RenewalWorkbenchResponse.OutgoingRenewal();

            item.setRenewalId(renewal.getRenewalid());
            item.setNewMemberCourseId(target.getMembercourseid());
            item.setCourseId(target.getCourse().getCourseid());
            item.setCourseName(target.getCourse().getCoursename());
            item.setPurchaseDate(target.getPurchasedate());
            item.setRenewalDate(renewal.getRenewaldate());

            result.add(item);
        }

        return result;
    }

    private List<String> buildTags(
            int remainingSessions,
            boolean hasRenewed,
            Long daysSinceBaseline
    ) {
        List<String> tags = new ArrayList<>();

        if (!hasRenewed) {
            if (remainingSessions >= 1
                    && remainingSessions <= 5) {
                tags.add("HIGH_PRIORITY");
            }

            if (remainingSessions >= 6
                    && remainingSessions <= 10) {
                tags.add("UPCOMING");
            }

            if (remainingSessions == 0) {
                tags.add("COMPLETED");
            }
        }

        if (remainingSessions > 0
                && daysSinceBaseline != null
                && daysSinceBaseline >= 14) {
            tags.add("LONG_ABSENT");
        }

        return tags;
    }

    private List<RenewalOverviewResponse.Reminder> buildReminders(
            int remainingSessions,
            boolean hasRenewed,
            List<String> tags,
            Long daysSinceBaseline
    ) {
        List<RenewalOverviewResponse.Reminder> reminders =
                new ArrayList<>();

        if (hasRenewed) {
            reminders.add(
                    reminder(
                            "RENEWED",
                            "此方案已有續約紀錄，可查看關聯的新方案。"
                    )
            );
        }

        for (String tag : tags) {
            String message = switch (tag) {
                case "HIGH_PRIORITY" ->
                        "剩餘" + remainingSessions
                                + "堂，建議主動聯繫，了解續課意願。";

                case "UPCOMING" ->
                        "剩餘" + remainingSessions
                                + "堂，可提前了解後續上課安排與續課意願。";

                case "COMPLETED" ->
                        "此方案堂數已用完，建議聯繫了解後續購課需求。";

                case "LONG_ABSENT" ->
                        "同課程已" + daysSinceBaseline
                                + "天未出席，建議聯繫了解上課安排。";

                default ->
                        throw new IllegalStateException(
                                "未知的追蹤分類：" + tag
                        );
            };

            reminders.add(reminder(tag, message));
        }

        return reminders;
    }

    private RenewalOverviewResponse.Reminder reminder(
            String type,
            String message
    ) {
        RenewalOverviewResponse.Reminder reminder =
                new RenewalOverviewResponse.Reminder();

        reminder.setType(type);
        reminder.setMessage(message);

        return reminder;
    }

    private RenewalOverviewResponse.Actions buildActions(
            Member member
    ) {
        RenewalOverviewResponse.Actions actions =
                new RenewalOverviewResponse.Actions();

        // 停用會員仍可新增關懷
        actions.setCanAddFollowup(true);

        String status = member.getStatus();

        if ("active".equals(status)) {
            actions.setCanRenew(true);
            actions.setRenewDisabledReason(null);
        } else if ("inactive".equals(status)) {
            actions.setCanRenew(false);

            actions.setRenewDisabledReason(
                    "此會員已停用，請先恢復會員後再辦理續約"
            );
        } else {
            log.error(
                    "未知會員狀態：memberId={}, status={}",
                    member.getMemberid(),
                    status
            );

            throw new IllegalStateException(
                    "會員狀態資料異常"
            );
        }

        return actions;
    }

    private String emptyToNull(String value) {
        if (value == null) {
            return null;
        }

        String stripped = value.strip();

        return stripped.isEmpty() ? null : stripped;
    }
}