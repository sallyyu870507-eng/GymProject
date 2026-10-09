package tw.gymproject.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tw.gymproject.entity.Attendance;

import java.util.List;
import java.util.Optional;

/*
AttendanceRepo 處理
某一筆 Booking 對應哪一筆 Attendance
+
某個 MemberCourse / Member 的歷史出席紀錄
 */
public interface AttendanceRepo extends JpaRepository<Attendance,Integer> {

    // 依 bookingId 找該次預約對應的出席紀錄
    Optional<Attendance> findByBooking_Bookingid(
            Integer bookingid
    );


    // 查某個 MemberCourse 的歷史出席，依上課日期由新到舊
    List<Attendance> findByBooking_Membercourse_MembercourseidOrderByBooking_Schedule_ClassdateDesc(
            Integer membercourseid
    );
}
