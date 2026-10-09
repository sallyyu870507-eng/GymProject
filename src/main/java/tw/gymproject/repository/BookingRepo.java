package tw.gymproject.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tw.gymproject.entity.Booking;

import java.time.LocalDate;
import java.util.List;

public interface BookingRepo extends JpaRepository<Booking,Integer> {

    /*
    Booking.schedule.classdate
            AND
    Booking.memberCourse.coach.coachid

    SELECT b.*
    FROM booking b
    JOIN classschedule s
        ON b.scheduleid = s.scheduleid
    JOIN membercourse mc
        ON b.membercourseid = mc.membercourseid
    WHERE s.classdate = ?
      AND mc.coachid = ?;

    bookingRepo.findBySchedule_ClassdateAndMemberCourse_Coach_Coachid(
        LocalDate.of(2026, 10, 8),
        1
    );
    ->查 2026/10/08，而且屬於 coach 1 的所有 Booking。
     */

    List<Booking> findBySchedule_ClassdateAndMembercourse_Coach_Coachid(
        LocalDate classdate,
        Integer coachid
    );
}
