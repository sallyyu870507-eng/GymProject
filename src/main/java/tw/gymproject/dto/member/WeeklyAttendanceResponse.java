package tw.gymproject.dto.member;

import java.time.LocalDate;

/** GET /api/member/attendance：某一週（週一開始）出席幾次 */
public record WeeklyAttendanceResponse(
        LocalDate week,
        int checkins) {
}
