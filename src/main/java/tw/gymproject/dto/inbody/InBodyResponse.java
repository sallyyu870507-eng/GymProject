package tw.gymproject.dto.inbody;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

/*
後端回傳 InBody 資料給前端
*/
@Data
public class InBodyResponse {

    // InBodyRecord.recorddate
    private LocalDate recordDate;

    // InBodyRecord.weight
    private BigDecimal weight;

    // InBodyRecord.bodyfatpct
    private BigDecimal bodyFatPct;

    // InBodyRecord.musclemass
    private BigDecimal muscleMass;
}