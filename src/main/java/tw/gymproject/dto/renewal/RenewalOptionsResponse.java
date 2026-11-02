package tw.gymproject.dto.renewal;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;


//用途:裝 P1 續約表單初始化資料，不會建立購課或續約紀錄
@Data
public class RenewalOptionsResponse {

    private Integer memberCourseId;

    private LocalDateTime asOfDateTime;

    private LocalDate today;

    private MemberInfo member;

    private SourceCourse sourceCourse;

    private CoachInfo coach;

    // 登入教練有授課配對，而且啟用的課程
    private List<CourseOption> courses = new ArrayList<>();

    // 原課程仍為合法選項時才預選
    private Integer defaultCourseId;

    private LocalDate defaultPurchaseDate;

    private LocalDate minPurchaseDate;

    private LocalDate maxPurchaseDate;

    private List<PaymentOption> paymentMethods = new ArrayList<>();

    private boolean canSubmit;

    private String disabledReason;

    @Data
    public static class MemberInfo {

        private Integer memberId;

        private String name;

        private String status;
    }

    @Data
    public static class SourceCourse {

        private Integer courseId;

        private String courseName;

        private LocalDate purchaseDate;

        private Integer totalSessions;

        private Integer remainingSessions;

        private Integer coachId;

        private String coachName;
    }

    @Data
    public static class CoachInfo {

        private Integer coachId;

        private String coachName;
    }

    @Data
    public static class CourseOption {

        private Integer courseId;

        private String courseName;
    }

    @Data
    public static class PaymentOption {

        private String value;

        private String label;
    }
}