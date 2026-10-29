package tw.gymproject.controller;

import java.util.List;
import java.util.Map;

import org.mindrot.jbcrypt.BCrypt;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.LoginResultDTO;

/**
 * 【僅供測試】簡易登入，讓 Postman 能在沒有組員登入功能的情況下測試 Dashboard API。
 * 登入成功後把 LoginResultDTO 放進 session 的 "user"（與組員的登入功能相同），
 * 所以 /api/member/** 與 /api/coach/schedules/** 會把你視為已登入。
 *
 * POST /api/test/login   (x-www-form-urlencoded: username, password)
 * POST /api/test/logout
 *
 * 合併到正式專案前請刪除這個檔案。
 */
@RestController
@RequestMapping("/api/test")
public class TestLoginController {

    private final NamedParameterJdbcTemplate jdbc;

    public TestLoginController(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @PostMapping("/login")
    public LoginResultDTO login(@RequestParam String username,
                                @RequestParam String password,
                                HttpSession session) {
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT ua.accountid, ua.username, ua.password, ua.role,
                       m.memberid, m.memberno, c.coachid, c.coachno,
                       COALESCE(m.name, c.name) AS name
                FROM useraccount ua
                LEFT JOIN member m ON m.accountid = ua.accountid
                LEFT JOIN coach  c ON c.accountid = ua.accountid
                WHERE ua.username = :username
                """, Map.of("username", username));

        if (rows.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "帳號不存在");
        }
        Map<String, Object> r = rows.get(0);
        String hash = (String) r.get("password");
        boolean ok;
        try {
            ok = hash != null && hash.startsWith("$2") ? BCrypt.checkpw(password, hash) : password.equals(hash);
        } catch (IllegalArgumentException e) {
            ok = false;
        }
        if (!ok) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "密碼錯誤");
        }

        LoginResultDTO user = new LoginResultDTO();
        user.setAccountid((Integer) r.get("accountid"));
        user.setUsername((String) r.get("username"));
        user.setRole((String) r.get("role"));
        user.setName((String) r.get("name"));
        user.setMemberid((Integer) r.get("memberid"));
        user.setMemberno((String) r.get("memberno"));
        user.setCoachid((Integer) r.get("coachid"));
        user.setCoachno((String) r.get("coachno"));
        user.setSuccess(true);

        session.setAttribute("user", user);
        return user;
    }

    @PostMapping("/logout")
    public Map<String, String> logout(HttpSession session) {
        session.invalidate();
        return Map.of("message", "已登出");
    }
}
