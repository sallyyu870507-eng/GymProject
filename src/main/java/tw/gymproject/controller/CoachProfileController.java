package tw.gymproject.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.coach.CoachProfileResponse;
import tw.gymproject.service.CoachSessionService;

/** 教練首頁頁首的身分資訊：GET /api/coach/profile */
@RestController
@RequestMapping("/api/coach")
public class CoachProfileController {

    private static final String SQL = """
            SELECT coachid, coachno, name, gender, phone, email, specialty, status
            FROM coach
            WHERE coachid = :coachid
            """;

    private final NamedParameterJdbcTemplate jdbc;
    private final CoachSessionService coachSession;

    public CoachProfileController(NamedParameterJdbcTemplate jdbc, CoachSessionService coachSession) {
        this.jdbc = jdbc;
        this.coachSession = coachSession;
    }

    @GetMapping("/profile")
    public CoachProfileResponse getProfile(HttpSession session) {
        Integer coachid = coachSession.getCurrentCoachId(session);
        List<CoachProfileResponse> rows = jdbc.query(SQL, new MapSqlParameterSource("coachid", coachid),
                (rs, i) -> new CoachProfileResponse(
                        rs.getInt("coachid"),
                        rs.getString("coachno"),
                        rs.getString("name"),
                        rs.getString("gender"),
                        rs.getString("phone"),
                        rs.getString("email"),
                        rs.getString("specialty"),
                        trim(rs.getString("status"))));
        if (rows.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "找不到教練資料");
        }
        return rows.get(0);
    }

    private static String trim(String s) {
        return s == null ? null : s.trim();
    }
}
