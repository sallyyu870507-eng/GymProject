package tw.gymproject.dto.renewal;

import lombok.Data;

import java.time.LocalDateTime;

//用途：裝「一筆關懷紀錄」。之後新增、編輯關懷也能沿用
@Data
public class FollowUpResponse {

    private Integer followupId;

    private Integer memberCourseId;

    // 聯繫時間，對應資料庫 createdate
    private LocalDateTime createdDate;

    // 這筆紀錄所記載的教練
    private Integer coachId;

    private String coachName;

    private String contactMethod;

    private String status;

    private String note;
}