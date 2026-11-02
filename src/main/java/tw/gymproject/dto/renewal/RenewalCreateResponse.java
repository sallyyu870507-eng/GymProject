package tw.gymproject.dto.renewal;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class RenewalCreateResponse {

    // 本次新增的續約紀錄 ID。
    private Integer renewalId;

    // 從哪個原方案辦理續約。
    private Integer sourceMemberCourseId;

    // 本次建立的新方案 ID。
    private Integer newMemberCourseId;

    // 會員資料。
    private Integer memberId;

    // 新方案課程。
    private Integer courseId;
    private String courseName;

    // 新方案教練。
    private Integer coachId;
    private String coachName;

    // 使用者選擇的購課日期，可補登。
    private LocalDate purchaseDate;

    // 系統實際登錄續約的時間。
    private LocalDateTime renewalDate;

    // 本次購買堂數。
    private Integer addedSessions;

    // 新方案建立時，總堂數與剩餘堂數都等於購買堂數。
    private Integer totalSessions;
    private Integer remainingSessions;

    // 新方案狀態。
    private String status;

    // 本次成交總金額與付款方式。
    private Integer amount;
    private String paymentMethod;

    // 本次續約備註。
    private String note;
}