package tw.gymproject.dto.renewal;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
public class InBodyPageResponse {

    private Integer memberCourseId;

    private LocalDateTime asOfDateTime;

    // 最新一筆有日期的有效量測
    private RecordItem latestRecord;

    private Trends trends = new Trends();

    // 當頁量測紀錄
    private List<RecordItem> items = new ArrayList<>();

    private PageInfo page;

    @Data
    public static class RecordItem {

        private Integer inBodyId;

        private Integer attendanceId;

        private LocalDate recordDate;

        private LocalDateTime classStartDateTime;

        private BigDecimal weight;

        private BigDecimal bodyFatPct;

        private BigDecimal muscleMass;
    }

    @Data
    public static class Trends {

        private List<TrendPoint> weight = new ArrayList<>();

        private List<TrendPoint> bodyFatPct = new ArrayList<>();

        private List<TrendPoint> muscleMass = new ArrayList<>();
    }

    @Data
    public static class TrendPoint {

        private Integer inBodyId;

        private Integer attendanceId;

        private LocalDate recordDate;

        private LocalDateTime classStartDateTime;

        private BigDecimal value;
    }

    @Data
    public static class PageInfo {

        private int number;

        private int size;

        private long totalElements;

        private int totalPages;

        private boolean hasPrevious;

        private boolean hasNext;
    }
}