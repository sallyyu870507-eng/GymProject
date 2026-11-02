package tw.gymproject.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.LoginResultDTO;

/**
 * 從 Session 取出目前登入的會員編號。
 * 登入由組員的 LoginController 負責，它會把 LoginResultDTO 放在 session 的 "user"。
 */
@Service
public class MemberSessionService {

    private final NamedParameterJdbcTemplate jdbc;

    public MemberSessionService(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Integer getCurrentMemberId(HttpSession session) {
        Object sessionUser = session == null ? null : session.getAttribute("user");
        if (!(sessionUser instanceof LoginResultDTO user)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "尚未登入或登入已失效");
        }

        if (!"member".equalsIgnoreCase(user.getRole())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "目前登入身分不是會員");
        }

        // 登入時通常已經放好 memberid；沒有的話用 accountid 反查
        if (user.getMemberid() != null) {
            return user.getMemberid();
        }
        if (user.getAccountid() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "登入資料不完整，請重新登入");
        }
        List<Integer> ids = jdbc.queryForList(
                "SELECT memberid FROM member WHERE accountid = :accountid",
                new MapSqlParameterSource("accountid", user.getAccountid()),
                Integer.class);
        if (ids.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "找不到登入帳號對應的會員");
        }
        return ids.get(0);
    }
}
