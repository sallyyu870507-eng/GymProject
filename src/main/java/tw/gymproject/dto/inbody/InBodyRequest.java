package tw.gymproject.dto.inbody;

import lombok.Data;

import java.math.BigDecimal;

/*
前端更新 Attendance 時，
若狀態為 PRESENT，可以一起送 InBody。

inBody = null：
→ 本次沒有量測 InBody
→ 不建立，也不修改既有資料

有傳 InBody：
→ weight、bodyFatPct、muscleMass 三項都必須完整填寫
→ 三項數值都必須大於 0
→ 第一次建立，重送則更新同一筆

只填部分欄位：
→ 視為不合法資料
*/
@Data
public class InBodyRequest {

    // InBodyRecord.weight
    private BigDecimal weight;

    // JSON: bodyFatPct
    // Entity: bodyfatpct
    private BigDecimal bodyFatPct;

    // JSON: muscleMass
    // Entity: musclemass
    private BigDecimal muscleMass;
}