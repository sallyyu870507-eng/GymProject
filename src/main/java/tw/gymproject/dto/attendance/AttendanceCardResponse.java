package tw.gymproject.dto.attendance;

import lombok.Data;

import java.time.LocalTime;

/*
API：
GET /api/coach/attendance?date=YYYY-MM-DD

用途：
今日課程 / 學員出席卡片
*/
@Data
public class AttendanceCardResponse {

    // Booking.bookingid
    private Integer bookingId;

    // Booking.schedule.scheduleid
    private Integer scheduleId;

    // ClassSchedule.starttime
    private LocalTime startTime;

    // ClassSchedule.endtime
    private LocalTime endTime;

    // Booking.membercourse.membercourseid
    private Integer memberCourseId;

    // Membercourse.member.memberid
    private Integer memberId;

    // Membercourse.member.name
    private String memberName;

    // Membercourse.member.avatarurl
    private String avatarUrl;

    // Membercourse.course.coursename
    private String courseName;

    // Membercourse.remainingsessions
    private Integer remainingSessions;

    // Booking.bookingstatus
    private String bookingStatus;

    /*
    Attendance.attendancestatus
    如果這筆 Booking 還沒有 Attendance：
    預設回傳 PENDING
    */
    private String attendanceStatus;
}
