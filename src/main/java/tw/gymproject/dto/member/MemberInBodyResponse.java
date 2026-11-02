package tw.gymproject.dto.member;

import java.math.BigDecimal;
import java.time.LocalDate;

/** GET /api/member/inbody：一筆 InBody 檢測紀錄 */
public record MemberInBodyResponse(
        Integer inbodyid,
        LocalDate recorddate,
        BigDecimal weight,
        BigDecimal bodyfatpct,
        BigDecimal musclemass) {
}
