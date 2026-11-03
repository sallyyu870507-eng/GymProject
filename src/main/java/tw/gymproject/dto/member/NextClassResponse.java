package tw.gymproject.dto.member;

import java.time.LocalDate;
import java.time.LocalTime;

/** GET /api/member/next-class：最近一堂還沒上的預約課 */
public record NextClassResponse(
        Integer bookingid,
        Integer scheduleid,
        LocalDate classdate,
        LocalTime starttime,
        LocalTime endtime,
        String coursename,
        String coursetype,
        String classroom,
        String coachname) {
}
