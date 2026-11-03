package tw.gymproject.dto.coach;

/** GET /api/coach/profile：登入教練自己的 coach 資料 */
public record CoachProfileResponse(
        Integer coachid,
        String coachno,
        String name,
        String gender,
        String phone,
        String email,
        String specialty,
        String status) {
}
