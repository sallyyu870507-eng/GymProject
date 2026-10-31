package tw.gymproject.dto.renewal;

import lombok.Data;
import java.util.ArrayList;
import java.util.List;

//用途：裝「一頁關懷紀錄＋分頁資訊＋整個方案最新紀錄」
@Data
public class FollowupPageResponse {

    private Integer memberCourseId;

    // 目前這一頁的紀錄
    private List<FollowUpResponse> items = new ArrayList<>();

    private PageInfo page;

    // 整個方案最新的一筆；完全沒有紀錄時為 null
    private FollowUpResponse latestFollowup;

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