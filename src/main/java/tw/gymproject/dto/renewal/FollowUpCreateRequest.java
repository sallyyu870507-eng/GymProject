package tw.gymproject.dto.renewal;

import com.fasterxml.jackson.annotation.JsonAnySetter;
import lombok.Data;
import tw.gymproject.exception.BusinessException;

@Data
public class FollowUpCreateRequest {

    // 聯繫時間：必填。
    // 先保留原始字串，由 Service 驗證格式及時間。
    private String createdDate;

    // 聯絡方式：必填。
    // PHONE、MESSAGE、IN_PERSON、OTHER
    private String contactMethod;

    // 聯繫結果：必填。
    // NO_RESPONSE、CONSIDERING、AGREED、DECLINED
    private String status;

    // 備註：選填。
    // 未傳、null 或空白，在 Service 統一轉為 null。
    private String note;

    // 拒絕規格以外的欄位，避免呼叫端誤以為可以修改。
    @JsonAnySetter
    public void rejectUnknownField(
            String fieldName,
            Object value
    ) {
        throw new BusinessException(
                "不支援的新增關懷欄位：" + fieldName
        );
    }
}