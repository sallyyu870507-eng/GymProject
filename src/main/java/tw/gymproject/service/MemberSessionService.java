package tw.gymproject.service;

import org.springframework.stereotype.Service;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.entity.Member;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.exception.UnauthorizedException;
import tw.gymproject.repository.MemberRepository;

/**
 * 從 Session 取出目前登入的會員編號（寫法比照 CoachSessionService）。
 */
@Service
public class MemberSessionService {

    private final MemberRepository memberRepository;

    public MemberSessionService(MemberRepository memberRepository) {
        this.memberRepository = memberRepository;
    }

    public Integer getCurrentMemberId(HttpSession session) {
        if (session == null) {
            throw new UnauthorizedException("尚未登入或登入已失效");
        }

        Object sessionUser = session.getAttribute("user");
        if (!(sessionUser instanceof LoginResultDTO user)) {
            throw new UnauthorizedException("尚未登入或登入已失效");
        }

        if (!"member".equalsIgnoreCase(user.getRole())) {
            throw new ForbiddenException("目前登入身分不是會員");
        }

        // 登入時通常已經放好 memberid；沒有的話用 accountid 反查
        if (user.getMemberid() != null) {
            return user.getMemberid();
        }
        if (user.getAccountid() == null) {
            throw new UnauthorizedException("登入資料不完整，請重新登入");
        }
        return memberRepository
                .findByAccount_Accountid(user.getAccountid())
                .map(Member::getMemberid)
                .orElseThrow(() -> new ForbiddenException("找不到登入帳號對應的會員"));
    }
}
