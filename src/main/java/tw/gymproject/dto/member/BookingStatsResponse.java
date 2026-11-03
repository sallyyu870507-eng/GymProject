package tw.gymproject.dto.member;

/** GET /api/member/booking-stats：預約次數統計 */
public record BookingStatsResponse(
        int completed,   // 已完成（bookingstatus = completed）
        int cancelled,   // 已取消（bookingstatus = cancelled）
        int upcoming) {  // 還沒上的預約（bookingstatus = booked，時間在現在之後）
}
