package tw.gymproject.dto.inbody;

import lombok.Data;

import java.math.BigDecimal;

/*
前端更新 Attendance 時，
若狀態為 PRESENT，可以一起送 InBody。

全部 null：
→ 不建立 InBody

任一欄非 null：
→ 建立 / 更新 InBody
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