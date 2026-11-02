package tw.gymproject.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import tw.gymproject.entity.Attendance;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
/*
AttendanceRepo 處理
某一筆 Booking 對應哪一筆 Attendance
+
某個 Membercourse / Member 的歷史出席紀錄
 */
public interface AttendanceRepo extends JpaRepository<Attendance,Integer> {

    // 依 bookingId 找該次預約對應的出席紀錄
    Optional<Attendance> findByBooking_Bookingid(
            Integer bookingid
    );


    // 查某個 Membercourse 的歷史出席，依上課日期由新到舊
    List<Attendance>
    findByBooking_Membercourse_MembercourseidOrderByBooking_Schedule_ClassdateDesc(
            Integer membercourseid
    );
    // 新增：續約工作台使用
    // 同會員＋同課程＋同教練，跨方案取得最後出席日
    @Query("""
            select
                mc.member.memberid as memberId,
                mc.course.courseid as courseId,
                mc.coach.coachid as coachId,
                max(s.classdate) as lastPresentDate
            from Attendance a
            join a.booking b
            join b.membercourse mc
            join b.schedule s
            where mc.coach.coachid = :coachId
              and a.attendancestatus = 'PRESENT'
              and lower(b.bookingstatus) <> 'cancelled'
              and s.classdate <= :asOfDate
            group by
                mc.member.memberid,
                mc.course.courseid,
                mc.coach.coachid
            """)
    List<CourseLastPresent> findCourseLastPresentDates(
            @Param("coachId") Integer coachId,
            @Param("asOfDate") LocalDate asOfDate
    );

    // 接收上述查詢結果，不是新增資料表
    interface CourseLastPresent {

        Integer getMemberId();

        Integer getCourseId();

        Integer getCoachId();

        LocalDate getLastPresentDate();
    }

    // B1：統計指定方案已開始課程的出席、請假、缺席次數
    @Query(
            value = """
                select
                    count_big(distinct case
                        when a.attendancestatus = 'PRESENT'
                        then b.bookingid
                        else null
                    end) as presentCount,

                    count_big(distinct case
                        when a.attendancestatus = 'LEAVE'
                        then b.bookingid
                        else null
                    end) as leaveCount,

                    count_big(distinct case
                        when a.attendancestatus = 'ABSENT'
                        then b.bookingid
                        else null
                    end) as absentCount

                from attendance a
                join booking b
                    on b.bookingid = a.bookingid
                join classschedule s
                    on s.scheduleid = b.scheduleid

                where b.membercourseid = :memberCourseId
                  and lower(b.bookingstatus) <> 'cancelled'
                  and (
                      s.classdate < cast(:asOfDate as date)
                      or (
                          s.classdate = cast(:asOfDate as date)
                          and s.starttime <= cast(:asOfTime as time)
                      )
                  )
                """,
            nativeQuery = true
    )

    AttendanceSummaryCounts findAttendanceSummary(
            @Param("memberCourseId") Integer memberCourseId,
            @Param("asOfDate") LocalDate asOfDate,
            @Param("asOfTime") LocalTime asOfTime
    );

    // 接收統計查詢結果的介面(AttendanceSummaryCounts 是查詢結果的接收介面，不是 Entity，不會新增資料表)
    interface AttendanceSummaryCounts {

        Long getPresentCount();

        Long getLeaveCount();

        Long getAbsentCount();
    }

}