package tw.gymproject.controller;

import java.sql.Date;
import java.sql.Time;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.LoginResultDTO;

/**
 * 教練首頁的「全館教練排課表」：GET /api/coach/schedules/gym?date=2026-11-03
 *
 * 獨立版本：不依賴其他 Service / DTO，登入檢查和 SQL 都在這個檔案裡，
 * 只用到登入功能的 LoginResultDTO（session 的 "user"）。
 * 回傳格式和管理員的 /admin/schedules/day 一樣。
 */
@RestController
@RequestMapping("/api/coach/schedules")
public class CoachGymScheduleController {

    /** 回傳給前端的一列（欄位名稱就是 JSON 的 key） */
    public record GymScheduleRow(
            Integer scheduleid,
            Integer coachid,
            String coachname,
            LocalDate classdate,
            LocalTime starttime,
            LocalTime endtime,
            String status,      // available / booked / 其他原本的狀態
            String membername,  // 沒人預約是 null
            String coursename) {
    }

    /**
     * 某一天全館所有時段：
     * 時段本身不是 open → 顯示原本狀態；有人預約（booked）→ booked；否則 available。
     * bookingstatus 用 LOWER 比對，大寫 BOOKED 的測試資料也算。
     */
    private static final String SQL = """
            SELECT cs.scheduleid,
                   cs.coachid,
                   co.name AS coachname,
                   cs.classdate,
                   cs.starttime,
                   cs.endtime,
                   CASE
                       WHEN LOWER(cs.status) <> 'open' THEN LOWER(cs.status)
                       WHEN b.bookingid IS NOT NULL THEN 'booked'
                       ELSE 'available'
                   END AS status,
                   m.name AS membername,
                   c.coursename
            FROM classschedule cs
            JOIN coach co ON co.coachid = cs.coachid
            LEFT JOIN course c ON c.courseid = cs.courseid
            OUTER APPLY (
                SELECT TOP 1 bk.bookingid, bk.membercourseid
                FROM booking bk
                WHERE bk.scheduleid = cs.scheduleid
                  AND LOWER(bk.bookingstatus) = 'booked'
                ORDER BY bk.bookingid DESC
            ) b
            LEFT JOIN membercourse mc ON mc.membercourseid = b.membercourseid
            LEFT JOIN member m ON m.memberid = mc.memberid
            WHERE cs.classdate = :classdate
            ORDER BY cs.starttime, cs.coachid
            """;

    private final NamedParameterJdbcTemplate jdbc;

    public CoachGymScheduleController(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping("/gym")
    public List<GymScheduleRow> getGymSchedule(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            HttpSession session) {

        // 1. 確認有登入、而且是教練
        Object sessionUser = session.getAttribute("user");
        if (!(sessionUser instanceof LoginResultDTO user)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "尚未登入或登入已失效");
        }
        if (!"coach".equalsIgnoreCase(user.getRole())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "目前登入身分不是教練");
        }

        // 2. 查全館排課
        return jdbc.query(
                SQL,
                new MapSqlParameterSource("classdate", Date.valueOf(date)),
                (rs, i) -> new GymScheduleRow(
                        rs.getInt("scheduleid"),
                        rs.getInt("coachid"),
                        rs.getString("coachname"),
                        toLocalDate(rs.getDate("classdate")),
                        toLocalTime(rs.getTime("starttime")),
                        toLocalTime(rs.getTime("endtime")),
                        rs.getString("status"),
                        rs.getString("membername"),
                        rs.getString("coursename")));
    }

    private static LocalDate toLocalDate(Date d) {
        return d == null ? null : d.toLocalDate();
    }

    private static LocalTime toLocalTime(Time t) {
        return t == null ? null : t.toLocalTime();
    }
}
