package tw.gymproject.dto.renewal;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AttendanceSummaryResponse {
    private Integer memberCourseId;

    private LocalDateTime asOfDateTime;

    private long presentCount;

    private long leaveCount;

    private long absentCount;
}
