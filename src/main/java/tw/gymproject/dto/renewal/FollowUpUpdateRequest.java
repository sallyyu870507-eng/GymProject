package tw.gymproject.dto.renewal;

import com.fasterxml.jackson.annotation.JsonAnySetter;
import lombok.Data;
import tw.gymproject.exception.BusinessException;

@Data
public class FollowUpUpdateRequest {

    // 聯繫時間：
    // 使用字串接收，後續由 Service 嚴格檢查格式
    private String createdDate;

    // PHONE、MESSAGE、IN_PERSON、OTHER
    private String contactMethod;

    // NO_RESPONSE、CONSIDERING、AGREED、DECLINED
    private String status;

    // 選填；省略或 null 表示清空
    private String note;

    // 必填：
    // false = 保留原聯繫時間
    // true = 明確修改聯繫時間
    private Boolean contactTimeChanged;

    // 拒絕傳入不允許修改的欄位
    @JsonAnySetter
    public void rejectUnknownField(
            String fieldName,
            Object value
    ) {
        throw new BusinessException(
                "不支援的修改欄位：" + fieldName
        );
    }
}