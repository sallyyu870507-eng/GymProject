package tw.gymproject.dto.member;

import java.time.LocalDate;

/** GET /api/member/profile：登入會員自己的 member 資料 */
public record MemberProfileResponse(
        Integer memberid,
        String memberno,
        String name,
        String gender,
        String phone,
        String email,
        LocalDate birthday,
        String avatarurl,
        String status) {
}
