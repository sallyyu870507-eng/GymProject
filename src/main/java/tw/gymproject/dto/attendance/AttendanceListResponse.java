package tw.gymproject.dto.attendance;

import lombok.Data;
import java.time.LocalDate;
import java.util.List;

/*
GET /api/attendance?date=YYYY-MM-DD

整個出席工作台的 Response
*/

/*
AttendanceListResponse
├── date
├── summary
│   └── AttendanceSummaryResponse
└── cards
    └── List<AttendanceCardResponse>
 */
@Data
public class AttendanceListResponse {

    // 使用者目前查看的日期
    private LocalDate date;

    // 上方統計
    private AttendanceSummaryResponse summary;

    // 當日所有課程 / 預約卡
    private List<AttendanceCardResponse> classes;
}