package tw.gymproject.dto.renewal;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
public class RenewalOverviewResponse {

    private LocalDate asOfDate;

    private LocalDateTime asOfDateTime;

    private Integer memberCourseId;

    private MemberInfo member;

    private CourseInfo course;

    private RenewalWorkbenchResponse.CourseActivity courseActivity;

    private List<String> tags = new ArrayList<>();

    private boolean hasRenewed;

    private List<RenewalWorkbenchResponse.OutgoingRenewal>
            outgoingRenewals = new ArrayList<>();

    private String followupStatus;

    private List<Reminder> reminders = new ArrayList<>();

    private Actions actions;

    @Data
    public static class MemberInfo {

        private Integer memberId;

        private String name;

        private String avatarUrl;

        private String gender;

        private Integer age;

        private String phone;

        private String email;

        private String status;
    }

    @Data
    public static class CourseInfo {

        private Integer courseId;

        private String courseName;

        private Integer coachId;

        private String coachName;

        private LocalDate purchaseDate;

        private Integer totalSessions;

        private Integer remainingSessions;

        private Integer usedSessions;

        private String status;
    }

    @Data
    public static class Reminder {

        private String type;

        private String message;
    }

    @Data
    public static class Actions {

        private boolean canAddFollowup;

        private boolean canRenew;

        private String renewDisabledReason;
    }
}