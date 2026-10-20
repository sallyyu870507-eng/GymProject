package tw.gymproject.dto.renewal;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
public class RenewalWorkbenchResponse {

    private LocalDate asOfDate;

    private Counts counts;

    private long authorizedPlanCount;

    private long trackingPlanCount;

    private List<PlanRow> items = new ArrayList<>();

    private PageInfo page;

    // 全部授權方案的分類統計，不受列表篩選影響
    @Data
    public static class Counts {

        private long highPriority;

        private long upcoming;

        private long longAbsent;

        private long completed;
    }

    // 工作台列表中的一筆購課方案
    @Data
    public static class PlanRow {

        private Integer memberCourseId;

        private Integer memberId;

        private String name;

        private String avatarUrl;

        private String memberStatus;

        private Integer courseId;

        private String courseName;

        private Integer coachId;

        private LocalDate purchaseDate;

        private Integer totalSessions;

        private Integer remainingSessions;

        private String status;

        private CourseActivity courseActivity;

        private List<String> tags = new ArrayList<>();

        private boolean hasRenewed;

        private List<OutgoingRenewal> outgoingRenewals =
                new ArrayList<>();

        private String followupStatus;

        private LocalDateTime latestFollowupDate;
    }

    // 同會員、同課程、同教練，跨方案計算的到課資訊
    @Data
    public static class CourseActivity {

        private LocalDate lastPresentDate;

        private Long daysSinceLastPresent;

        private String baselineType;

        private LocalDate baselineDate;

        private Long daysSinceBaseline;
    }

    // 來源方案曾經辦理的每一筆續約
    @Data
    public static class OutgoingRenewal {

        private Integer renewalId;

        private Integer newMemberCourseId;

        private Integer courseId;

        private String courseName;

        private LocalDate purchaseDate;

        private LocalDateTime renewalDate;
    }

    @Data
    public static class PageInfo {

        private int number;

        private int size;

        private long totalElements;

        private int totalPages;

        private boolean hasPrevious;

        private boolean hasNext;
    }
}