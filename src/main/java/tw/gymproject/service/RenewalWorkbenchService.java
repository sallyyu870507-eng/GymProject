package tw.gymproject.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import tw.gymproject.dto.renewal.RenewalWorkbenchResponse;
import tw.gymproject.dto.renewal.RenewalWorkbenchResponse.*;
import tw.gymproject.entity.FollowUp;
import tw.gymproject.entity.MemberCourse;
import tw.gymproject.entity.Renewal;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.repository.AttendanceRepo;
import tw.gymproject.repository.FollowUpRepo;
import tw.gymproject.repository.MemberCourseRepo;
import tw.gymproject.repository.RenewalRepo;
import tw.gymproject.repository.RenewalWorkbenchRepo;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class RenewalWorkbenchService {

    private static final Logger log =
            LoggerFactory.getLogger(RenewalWorkbenchService.class);

    private static final ZoneId TAIPEI =
            ZoneId.of("Asia/Taipei");

    private static final int PAGE_SIZE = 10;

    private static final Set<String> SCOPES =
            Set.of("TRACKING", "ALL_PLANS");

    private static final Set<String> CATEGORIES =
            Set.of(
                    "ALL",
                    "HIGH_PRIORITY",
                    "UPCOMING",
                    "LONG_ABSENT",
                    "COMPLETED"
            );

    private static final Set<String> FOLLOWUP_STATUSES =
            Set.of(
                    "ALL",
                    "NOT_CONTACTED",
                    "NO_RESPONSE",
                    "CONSIDERING",
                    "AGREED",
                    "DECLINED"
            );

    private final RenewalWorkbenchRepo workbenchRepo;
    private final MemberCourseRepo memberCourseRepo;
    private final AttendanceRepo attendanceRepo;
    private final FollowUpRepo followUpRepo;
    private final RenewalRepo renewalRepo;

    public RenewalWorkbenchService(
            RenewalWorkbenchRepo workbenchRepo,
            MemberCourseRepo memberCourseRepo,
            AttendanceRepo attendanceRepo,
            FollowUpRepo followUpRepo,
            RenewalRepo renewalRepo
    ) {
        this.workbenchRepo = workbenchRepo;
        this.memberCourseRepo = memberCourseRepo;
        this.attendanceRepo = attendanceRepo;
        this.followUpRepo = followUpRepo;
        this.renewalRepo = renewalRepo;
    }

    /*
     * 所有工作台資料在同一個交易內讀取。
     * SERIALIZABLE 保護多次查詢的一致性；
     * 不是單靠 readOnly 就能達成。
     *
     * 此方法必須由另一個 Spring Bean（Controller）呼叫，
     * 才會經過 Spring 的交易代理。
     */
    @Transactional(
            readOnly = true,
            isolation = Isolation.SERIALIZABLE
    )
    public RenewalWorkbenchResponse getWorkbench(
            Integer coachId,
            String scope,
            String keyword,
            String category,
            String followupStatus,
            Integer page,
            Integer size
    ) {
        // 1. 驗證查詢參數
        validateQuery(
                coachId,
                scope,
                category,
                followupStatus,
                page,
                size
        );

        String searchKeyword =
                keyword == null ? "" : keyword.strip();

        // 本次請求只取一次時間
        LocalDateTime asOfDateTime =
                LocalDateTime.now(TAIPEI);

        LocalDate asOfDate =
                asOfDateTime.toLocalDate();

        // 2. 全授權範圍統計：不受列表條件影響
        RenewalWorkbenchRepo.CountsResult result =
                workbenchRepo.findCounts(coachId, asOfDate);

        Counts counts = new Counts();
        counts.setHighPriority(result.highPriority());
        counts.setUpcoming(result.upcoming());
        counts.setLongAbsent(result.longAbsent());
        counts.setCompleted(result.completed());

        // 3. 篩選後總筆數
        long totalElements = workbenchRepo.countFiltered(
                coachId,
                asOfDate,
                scope,
                searchKeyword,
                category,
                followupStatus
        );

        // 4. 計算實際頁碼，超頁時回最後一頁
        int totalPages = Math.toIntExact(
                totalElements / PAGE_SIZE
                        + (totalElements % PAGE_SIZE == 0 ? 0 : 1)
        );

        int actualPage = totalPages == 0
                ? 1
                : Math.min(page, totalPages);

        long offset =
                (actualPage - 1L) * PAGE_SIZE;

        // 5. 資料庫排序、分頁後取得 ID
        List<Integer> planIds = totalElements == 0
                ? List.of()
                : workbenchRepo.findPageIds(
                coachId,
                asOfDate,
                scope,
                searchKeyword,
                category,
                followupStatus,
                offset
        );

        List<PlanRow> items = new ArrayList<>();

        if (!planIds.isEmpty()) {
            // 6. 載入本頁方案與會員、課程
            List<MemberCourse> plans =
                    memberCourseRepo.findWorkbenchPlansByIds(
                            coachId,
                            planIds
                    );

            if (plans.size() != planIds.size()) {
                throw new IllegalStateException(
                        "工作台方案查詢結果不一致"
                );
            }

            // 7. 載入同組最後出席日
            Map<ActivityKey, LocalDate> lastPresentDates =
                    loadLastPresentDates(coachId, asOfDate);

            // 8. 載入同組最早購買日
            Map<ActivityKey, LocalDate> firstPurchaseDates =
                    loadFirstPurchaseDates(coachId, asOfDate);

            // 9. 每個方案的最新跟進
            Map<Integer, FollowUp> latestFollowups =
                    loadLatestFollowups(coachId);

            // 10. 每個來源方案的全部續約關係
            Map<Integer, List<OutgoingRenewal>> outgoingRenewals =
                    loadOutgoingRenewals(coachId);

            // 11. Entity → DTO
            for (MemberCourse plan : plans) {
                Integer planId = plan.getMembercourseid();

                ActivityKey key = new ActivityKey(
                        plan.getMember().getMemberid(),
                        plan.getCourse().getCourseid(),
                        plan.getCoach().getCoachid()
                );

                CourseActivity activity = buildActivity(
                        planId,
                        asOfDate,
                        lastPresentDates.get(key),
                        firstPurchaseDates.get(key)
                );

                List<OutgoingRenewal> renewals =
                        outgoingRenewals.getOrDefault(
                                planId,
                                List.of()
                        );

                boolean hasRenewed = !renewals.isEmpty();

                validateSessions(plan);

                List<String> tags = buildTags(
                        plan.getRemainingsessions(),
                        hasRenewed,
                        activity.getDaysSinceBaseline()
                );

                PlanRow row = new PlanRow();

                row.setMemberCourseId(planId);
                row.setMemberId(plan.getMember().getMemberid());
                row.setName(plan.getMember().getName());
                row.setAvatarUrl(plan.getMember().getAvatarurl());
                row.setMemberStatus(plan.getMember().getStatus());

                row.setCourseId(plan.getCourse().getCourseid());
                row.setCourseName(plan.getCourse().getCoursename());
                row.setCoachId(plan.getCoach().getCoachid());

                row.setPurchaseDate(plan.getPurchasedate());
                row.setTotalSessions(plan.getTotalsessions());
                row.setRemainingSessions(plan.getRemainingsessions());
                row.setStatus(plan.getStatus());

                row.setCourseActivity(activity);
                row.setTags(tags);
                row.setHasRenewed(hasRenewed);
                row.setOutgoingRenewals(renewals);

                FollowUp latest = latestFollowups.get(planId);

                if (latest == null) {
                    row.setFollowupStatus("NOT_CONTACTED");
                    row.setLatestFollowupDate(null);
                } else {
                    // 有紀錄但狀態為 null／未知，保留原值
                    row.setFollowupStatus(latest.getStatus());
                    row.setLatestFollowupDate(latest.getCreatedate());
                }

                items.add(row);
            }
        }

        // 12. 分頁資訊
        PageInfo pageInfo = new PageInfo();
        pageInfo.setNumber(actualPage);
        pageInfo.setSize(PAGE_SIZE);
        pageInfo.setTotalElements(totalElements);
        pageInfo.setTotalPages(totalPages);
        pageInfo.setHasPrevious(actualPage > 1);
        pageInfo.setHasNext(actualPage < totalPages);

        // 13. 最外層回應
        RenewalWorkbenchResponse response =
                new RenewalWorkbenchResponse();

        response.setAsOfDate(asOfDate);
        response.setCounts(counts);
        response.setAuthorizedPlanCount(
                result.authorizedPlanCount()
        );
        response.setTrackingPlanCount(
                result.trackingPlanCount()
        );
        response.setItems(items);
        response.setPage(pageInfo);

        return response;
    }

    private void validateQuery(
            Integer coachId,
            String scope,
            String category,
            String followupStatus,
            Integer page,
            Integer size
    ) {
        if (coachId == null || coachId <= 0) {
            throw new IllegalStateException("登入教練資料不完整");
        }

        if (scope == null || !SCOPES.contains(scope)) {
            throw new BusinessException(
                    "scope 只允許 TRACKING、ALL_PLANS"
            );
        }

        if (category == null || !CATEGORIES.contains(category)) {
            throw new BusinessException("category 不合法");
        }

        if (followupStatus == null
                || !FOLLOWUP_STATUSES.contains(followupStatus)) {
            throw new BusinessException("followupStatus 不合法");
        }

        if (page == null || page < 1) {
            throw new BusinessException("page 必須為大於 0 的整數");
        }

        if (size == null || size != PAGE_SIZE) {
            throw new BusinessException("size 只允許 10");
        }
    }

    private Map<ActivityKey, LocalDate> loadLastPresentDates(
            Integer coachId,
            LocalDate asOfDate
    ) {
        Map<ActivityKey, LocalDate> dates = new HashMap<>();

        for (AttendanceRepo.CourseLastPresent result
                : attendanceRepo.findCourseLastPresentDates(
                coachId, asOfDate
        )) {

            dates.put(
                    new ActivityKey(
                            result.getMemberId(),
                            result.getCourseId(),
                            result.getCoachId()
                    ),
                    result.getLastPresentDate()
            );
        }

        return dates;
    }

    private Map<ActivityKey, LocalDate> loadFirstPurchaseDates(
            Integer coachId,
            LocalDate asOfDate
    ) {
        Map<ActivityKey, LocalDate> dates = new HashMap<>();

        for (MemberCourseRepo.CourseFirstPurchase result
                : memberCourseRepo.findCourseFirstPurchaseDates(
                coachId, asOfDate
        )) {

            dates.put(
                    new ActivityKey(
                            result.getMemberId(),
                            result.getCourseId(),
                            result.getCoachId()
                    ),
                    result.getFirstPurchaseDate()
            );
        }

        return dates;
    }

    private Map<Integer, FollowUp> loadLatestFollowups(
            Integer coachId
    ) {
        Map<Integer, FollowUp> results = new HashMap<>();

        for (FollowUp followUp
                : followUpRepo.findLatestForCoachPlans(coachId)) {

            results.put(
                    followUp.getMemberCourse().getMembercourseid(),
                    followUp
            );
        }

        return results;
    }

    private Map<Integer, List<OutgoingRenewal>>
    loadOutgoingRenewals(Integer coachId) {

        Map<Integer, List<OutgoingRenewal>> results =
                new HashMap<>();

        // Repository 已依 renewaldate DESC、renewalid DESC 排序
        for (Renewal renewal
                : renewalRepo.findWorkbenchRenewals(coachId)) {

            Integer sourceId =
                    renewal.getMemberCourse().getMembercourseid();

            MemberCourse target =
                    renewal.getNewMemberCourse();

            OutgoingRenewal item = new OutgoingRenewal();
            item.setRenewalId(renewal.getRenewalid());
            item.setNewMemberCourseId(target.getMembercourseid());
            item.setCourseId(target.getCourse().getCourseid());
            item.setCourseName(target.getCourse().getCoursename());
            item.setPurchaseDate(target.getPurchasedate());
            item.setRenewalDate(renewal.getRenewaldate());

            results.computeIfAbsent(
                    sourceId,
                    ignored -> new ArrayList<>()
            ).add(item);
        }

        return results;
    }

    private CourseActivity buildActivity(
            Integer planId,
            LocalDate asOfDate,
            LocalDate lastPresentDate,
            LocalDate firstPurchaseDate
    ) {
        CourseActivity activity = new CourseActivity();

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

        } else if (firstPurchaseDate != null) {
            activity.setDaysSinceLastPresent(null);
            activity.setBaselineType("FIRST_PURCHASE");
            activity.setBaselineDate(firstPurchaseDate);
            activity.setDaysSinceBaseline(
                    ChronoUnit.DAYS.between(
                            firstPurchaseDate,
                            asOfDate
                    )
            );

        } else {
            // 沒有合法基準，不虛構 0 天，也不判久未到課
            activity.setDaysSinceLastPresent(null);
            activity.setBaselineType(null);
            activity.setBaselineDate(null);
            activity.setDaysSinceBaseline(null);

            log.warn(
                    "續約工作台方案 {} 缺少合法活動基準，查詢日 {}",
                    planId,
                    asOfDate
            );
        }

        return activity;
    }

    private List<String> buildTags(
            int remaining,
            boolean hasRenewed,
            Long daysSinceBaseline
    ) {
        List<String> tags = new ArrayList<>();

        if (!hasRenewed) {
            if (remaining >= 1 && remaining <= 5) {
                tags.add("HIGH_PRIORITY");
            }

            if (remaining >= 6 && remaining <= 10) {
                tags.add("UPCOMING");
            }

            if (remaining == 0) {
                tags.add("COMPLETED");
            }
        }

        // 已續約仍可能久未到課
        if (remaining > 0
                && daysSinceBaseline != null
                && daysSinceBaseline >= 14) {
            tags.add("LONG_ABSENT");
        }

        return tags;
    }

    private void validateSessions(MemberCourse plan) {
        Integer total = plan.getTotalsessions();
        Integer remaining = plan.getRemainingsessions();

        if (total == null
                || remaining == null
                || total <= 0
                || remaining < 0
                || remaining > total) {
            throw new IllegalStateException(
                    "方案堂數資料異常，方案 ID："
                            + plan.getMembercourseid()
            );
        }
    }

    // 同組活動的識別：會員＋課程＋教練
    private record ActivityKey(
            Integer memberId,
            Integer courseId,
            Integer coachId
    ) {
    }
}