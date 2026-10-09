package tw.gymproject.dto.attendance;

import lombok.Data;

import java.time.LocalDate;

/*
GET /api/attendance/{bookingId}

最近出席歷史
目前規格：
最多 5 筆
依課程日期 / 時間由新到舊
排除目前這一次 Booking
*/
@Data
public class AttendanceHistoryResponse {

    // ClassSchedule.classdate
    private LocalDate date;

    // Attendance.attendancestatus
    private String status;

    // Attendance.workoutfocus
    private String workoutFocus;

    // Attendance.note
    private String note;
}