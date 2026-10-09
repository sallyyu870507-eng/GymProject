package tw.gymproject.dto.attendance;

import lombok.Data;
import tw.gymproject.dto.inbody.InBodyRequest;

/*
PUT /api/attendance/{bookingId}

教練按儲存時，
React 傳給 Spring Boot 的資料
*/
@Data
public class AttendanceUpdateRequest {

    /*
    目前只接受：
    PRESENT
    LEAVE
    ABSENT

    PENDING 是初始狀態，
    不透過 PUT 設定
    */
    private String status;

    // Attendance.workoutfocus
    private String workoutFocus;

    // Attendance.note
    private String note;

    // PRESENT 時可選
    private InBodyRequest inBody;
}