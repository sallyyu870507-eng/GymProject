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
 * 從 Session 取出目前登入的教練編號（和 MemberSessionService 相同做法）。
 * 沒登入 → 401；登入的不是教練 → 403。
 */
@Service
public class CoachSessionService {

    private final NamedParameterJdbcTemplate jdbc;

    public CoachSessionService(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** 確認有登入、而且是教練 */
    public LoginResultDTO requireCoach(HttpSession session) {
        Object sessionUser = session == null ? null : session.getAttribute("user");
        if (!(sessionUser instanceof LoginResultDTO user)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "尚未登入或登入已失效");
        }
        if (!"coach".equalsIgnoreCase(user.getRole())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "目前登入身分不是教練");
        }
        return user;
    }

    /** 登入時通常已經放好 coachid；沒有的話用 accountid 反查 */
    public Integer getCurrentCoachId(HttpSession session) {
        LoginResultDTO user = requireCoach(session);
        if (user.getCoachid() != null) {
            return user.getCoachid();
        }
        List<Integer> ids = jdbc.queryForList(
                "SELECT coachid FROM coach WHERE accountid = :accountid",
                new MapSqlParameterSource("accountid", user.getAccountid()),
                Integer.class);
        if (ids.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "找不到登入帳號對應的教練");
        }
        return ids.get(0);
    }
}
