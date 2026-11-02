package tw.gymproject.dto.renewal;

import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonSetter;
import com.fasterxml.jackson.databind.JsonNode;

import lombok.Data;

import tw.gymproject.exception.BusinessException;

@Data
public class RenewalCreateRequest {

    // 新方案選擇的課程。
    private Integer courseId;

    // 新方案購買堂數，不增加到原方案。
    private Integer addedSessions;

    // 本次成交總金額，不是單堂價格。
    private Integer amount;

    // cash、transfer、card。
    private String paymentMethod;

    // 保留原始字串，由 Service 驗證日期格式及範圍。
    private String purchaseDate;

    // 選填備註。
    private String note;

    /*
     * 嚴格接收 JSON 整數。
     * 拒絕小數、數字字串、布林值及超過 Integer 範圍。
     */
    @JsonSetter("courseId")
    public void setCourseId(JsonNode value) {
        this.courseId = readInteger(value, "courseId");
    }

    @JsonSetter("addedSessions")
    public void setAddedSessions(JsonNode value) {
        this.addedSessions = readInteger(
                value,
                "addedSessions"
        );
    }

    @JsonSetter("amount")
    public void setAmount(JsonNode value) {
        this.amount = readInteger(value, "amount");
    }

    private static Integer readInteger(
            JsonNode value,
            String fieldName
    ) {
        // 缺少或 null 的必填檢查交給 Service。
        if (value == null || value.isNull()) {
            return null;
        }

        if (!value.isIntegralNumber()
                || !value.canConvertToInt()) {
            throw new BusinessException(
                    fieldName
                            + " 必須為 Integer 範圍內的 JSON 整數"
            );
        }

        return value.intValue();
    }

    // 不接受前端指定會員、教練、方案狀態等額外欄位。
    @JsonAnySetter
    public void rejectUnknownField(
            String fieldName,
            Object value
    ) {
        throw new BusinessException(
                "不支援的續約欄位：" + fieldName
        );
    }
}