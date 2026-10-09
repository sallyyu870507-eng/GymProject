package tw.gymproject.dto.attendance;

import lombok.Data;

/*
API：
GET /api/attendance?date=YYYY-MM-DD

用途：
出席管理頁上方統計卡
*/
@Data
public class AttendanceSummaryResponse {

    // 當天回傳的 Booking 卡片總數，包含取消預約
    private Integer totalClasses;

    // 尚未處理
    private Integer pending;

    // 已出席
    private Integer present;

    // 請假
    private Integer leave;

    // 缺席
    private Integer absent;

    // 已取消預約
    private Integer cancelled;
}