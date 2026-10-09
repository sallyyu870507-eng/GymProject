package tw.gymproject.dto.attendance;

import lombok.Data;
import tw.gymproject.dto.inbody.InBodyResponse;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

/*
GET /api/attendance/{bookingId}

回傳：
bookingId
classInfo
member
course
attendance
history
*/

@Data
public class AttendanceDetailResponse {

    private Integer bookingId;
    private ClassInfo classInfo;
    private MemberInfo member;
    private CourseInfo course;
    private AttendanceInfo attendance;
    private List<AttendanceHistoryResponse> history;



    // 課程時間資訊
    @Data
    public static class ClassInfo {

        // Booking.schedule.classdate
        private LocalDate date;

        // Booking.schedule.starttime
        private LocalTime startTime;

        // Booking.schedule.endtime
        private LocalTime endTime;
    }


    // 會員資訊
    @Data
    public static class MemberInfo {

        // Member.memberid
        private Integer memberId;

        // Member.name
        private String name;

        // Member.gender
        private String gender;

        // Member.phone
        private String phone;

        // Member.email
        private String email;

        // Member.avatarurl
        private String avatarUrl;
    }


    // 購課方案資訊
    @Data
    public static class CourseInfo {

        // MemberCourse.membercourseid
        private Integer memberCourseId;

        // MemberCourse.course.coursename
        private String courseName;

        // MemberCourse.totalsessions
        private Integer totalSessions;

        // MemberCourse.remainingsessions
        private Integer remainingSessions;

        /*
        最近一次 PRESENT 的上課日期。
        沒有歷史 PRESENT：
        null
        */
        private LocalDate lastPresentDate;
    }

    // 本次 Attendance
    @Data
    public static class AttendanceInfo {

        //如果 DB 還沒有 Attendance：null
        private Integer attendanceId;

        //沒有 Attendance：PENDING
        private String status;

        // Attendance.checkintime
        private LocalDateTime checkInTime;

        // Attendance.workoutfocus
        private String workoutFocus;

        // Attendance.note
        private String note;

        //沒有 InBody：null
        private InBodyResponse inBody;
    }
}