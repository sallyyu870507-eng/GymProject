package tw.gymproject.service;

import java.sql.Date;
import java.sql.Time;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.List;
import java.util.TreeMap;

import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import tw.gymproject.dto.member.BookingStatsResponse;
import tw.gymproject.dto.member.MemberCourseResponse;
import tw.gymproject.dto.member.MemberInBodyResponse;
import tw.gymproject.dto.member.NextClassResponse;
import tw.gymproject.dto.member.MemberProfileResponse;
import tw.gymproject.dto.member.WeeklyAttendanceResponse;

/**
 * 會員端 Dashboard 用的唯讀查詢：個人資料、每週出席次數、InBody 紀錄、
 * 下一堂課、課程剩餘堂數、預約次數統計。
 * 只讀資料、不新增也不修改，所以直接用 SQL 查，不另外建 Repository。
 */
@Service
public class MemberDashboardService {

    private final NamedParameterJdbcTemplate jdbc;

    public MemberDashboardService(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /* ───────── 個人資料 ───────── */

    private static final String SQL_PROFILE = """
            SELECT memberid, memberno, name, gender, phone, email,
                   birthday, avatarurl, status
            FROM member
            WHERE memberid = :memberid
            """;

    public MemberProfileResponse getProfile(Integer memberid) {
        List<MemberProfileResponse> rows = jdbc.query(
                SQL_PROFILE,
                new MapSqlParameterSource("memberid", memberid),
                (rs, i) -> new MemberProfileResponse(
                        rs.getInt("memberid"),
                        rs.getString("memberno"),
                        rs.getString("name"),
                        rs.getString("gender"),
                        rs.getString("phone"),
                        rs.getString("email"),
                        toLocalDate(rs.getDate("birthday")),
                        rs.getString("avatarurl"),
                        trim(rs.getString("status"))));

        if (rows.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "找不到會員資料");
        }
        return rows.get(0);
    }

    /* ───────── 每週出席次數 ───────── */

    /**
     * 出席（PRESENT）的日期：有簽到時間用簽到時間，沒有就用上課日期。
     * 已取消的預約不算。
     */
    private static final String SQL_PRESENT_DATES = """
            SELECT COALESCE(CAST(a.checkintime AS date), s.classdate) AS presentdate
            FROM attendance a
            JOIN booking b        ON b.bookingid = a.bookingid
            JOIN membercourse mc  ON mc.membercourseid = b.membercourseid
            JOIN classschedule s  ON s.scheduleid = b.scheduleid
            WHERE mc.memberid = :memberid
              AND UPPER(a.attendancestatus) = 'PRESENT'
              AND LOWER(b.bookingstatus) <> 'cancelled'
            """;

    /**
     * 回傳最近 weeks 週，每週（週一開始）出席幾次，沒出席的週補 0，由舊到新排序。
     * 「最近」以「本週」和「最後一次出席的那週」較晚的那個為準，
     * 這樣測試資料放在未來日期也看得到。
     */
    public List<WeeklyAttendanceResponse> getWeeklyAttendance(Integer memberid, int weeks) {
        int count = Math.max(1, Math.min(weeks, 52));

        List<LocalDate> dates = jdbc.query(
                SQL_PRESENT_DATES,
                new MapSqlParameterSource("memberid", memberid),
                (rs, i) -> toLocalDate(rs.getDate("presentdate")));

        TreeMap<LocalDate, Integer> perWeek = new TreeMap<>();
        for (LocalDate d : dates) {
            if (d != null) {
                perWeek.merge(mondayOf(d), 1, Integer::sum);
            }
        }

        LocalDate lastWeek = mondayOf(LocalDate.now());
        if (!perWeek.isEmpty()) {
            LocalDate latest = perWeek.lastKey();
            if (latest.isAfter(lastWeek)) {
                lastWeek = latest;
            }
        }

        List<WeeklyAttendanceResponse> result = new ArrayList<>(count);
        for (int i = count - 1; i >= 0; i--) {
            LocalDate week = lastWeek.minusWeeks(i);
            result.add(new WeeklyAttendanceResponse(week, perWeek.getOrDefault(week, 0)));
        }
        return result;
    }

    /* ───────── InBody ───────── */

    /** 檢測日期沒填時，用那堂課的上課日期 */
    private static final String SQL_INBODY = """
            SELECT i.inbodyid,
                   COALESCE(i.recorddate, s.classdate) AS recorddate,
                   i.weight, i.bodyfatpct, i.musclemass
            FROM inbodyrecords i
            LEFT JOIN attendance a    ON a.attendanceid = i.attendanceid
            LEFT JOIN booking b       ON b.bookingid = a.bookingid
            LEFT JOIN classschedule s ON s.scheduleid = b.scheduleid
            WHERE i.memberid = :memberid
              AND (i.weight IS NOT NULL OR i.bodyfatpct IS NOT NULL OR i.musclemass IS NOT NULL)
            ORDER BY COALESCE(i.recorddate, s.classdate), i.inbodyid
            """;

    public List<MemberInBodyResponse> getInBodyRecords(Integer memberid) {
        return jdbc.query(
                SQL_INBODY,
                new MapSqlParameterSource("memberid", memberid),
                (rs, i) -> new MemberInBodyResponse(
                        rs.getInt("inbodyid"),
                        toLocalDate(rs.getDate("recorddate")),
                        rs.getBigDecimal("weight"),
                        rs.getBigDecimal("bodyfatpct"),
                        rs.getBigDecimal("musclemass")));
    }

    /* ───────── 小工具 ───────── */

    private static LocalDate mondayOf(LocalDate d) {
        return d.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    }

    /* ───────── 下一堂課 ───────── */

    /** 還沒上的預約（booked）裡，時間最早的一堂 */
    private static final String SQL_NEXT_CLASS = """
            SELECT TOP 1 b.bookingid, s.scheduleid, s.classdate, s.starttime, s.endtime,
                   c.coursename, c.coursetype, s.classroom, co.name AS coachname
            FROM booking b
            JOIN membercourse mc  ON mc.membercourseid = b.membercourseid
            JOIN classschedule s  ON s.scheduleid = b.scheduleid
            JOIN course c         ON c.courseid = s.courseid
            JOIN coach co         ON co.coachid = s.coachid
            WHERE mc.memberid = :memberid
              AND LOWER(b.bookingstatus) = 'booked'
              AND (s.classdate > :today OR (s.classdate = :today AND s.starttime > :now))
            ORDER BY s.classdate, s.starttime
            """;

    /** 沒有下一堂課時回傳 null（Controller 會回 204 No Content） */
    public NextClassResponse getNextClass(Integer memberid) {
        LocalDateTime now = LocalDateTime.now();
        MapSqlParameterSource params = new MapSqlParameterSource("memberid", memberid)
                .addValue("today", Date.valueOf(now.toLocalDate()))
                .addValue("now", Time.valueOf(now.toLocalTime().withNano(0)));
        List<NextClassResponse> rows = jdbc.query(SQL_NEXT_CLASS, params,
                (rs, i) -> new NextClassResponse(
                        rs.getInt("bookingid"),
                        rs.getInt("scheduleid"),
                        toLocalDate(rs.getDate("classdate")),
                        toLocalTime(rs.getTime("starttime")),
                        toLocalTime(rs.getTime("endtime")),
                        rs.getString("coursename"),
                        rs.getString("coursetype"),
                        rs.getString("classroom"),
                        rs.getString("coachname")));
        return rows.isEmpty() ? null : rows.get(0);
    }

    /* ───────── 課程剩餘堂數 ───────── */

    /** 使用中（active）的課程方案，剩餘堂數少的排前面 */
    private static final String SQL_COURSES = """
            SELECT mc.membercourseid, c.coursename, co.name AS coachname,
                   mc.totalsessions, mc.remainingsessions, mc.purchasedate, mc.status
            FROM membercourse mc
            JOIN course c  ON c.courseid = mc.courseid
            JOIN coach co  ON co.coachid = mc.coachid
            WHERE mc.memberid = :memberid
              AND LOWER(mc.status) = 'active'
            ORDER BY mc.remainingsessions, mc.purchasedate DESC
            """;

    public List<MemberCourseResponse> getCourses(Integer memberid) {
        return jdbc.query(SQL_COURSES, new MapSqlParameterSource("memberid", memberid),
                (rs, i) -> new MemberCourseResponse(
                        rs.getInt("membercourseid"),
                        rs.getString("coursename"),
                        rs.getString("coachname"),
                        rs.getInt("totalsessions"),
                        rs.getInt("remainingsessions"),
                        toLocalDate(rs.getDate("purchasedate")),
                        trim(rs.getString("status"))));
    }

    /* ───────── 預約次數統計 ───────── */

    private static final String SQL_BOOKING_STATS = """
            SELECT
              SUM(CASE WHEN LOWER(b.bookingstatus) = 'completed' THEN 1 ELSE 0 END) AS completed,
              SUM(CASE WHEN LOWER(b.bookingstatus) = 'cancelled' THEN 1 ELSE 0 END) AS cancelled,
              SUM(CASE WHEN LOWER(b.bookingstatus) = 'booked'
                        AND (s.classdate > :today OR (s.classdate = :today AND s.starttime > :now))
                       THEN 1 ELSE 0 END) AS upcoming
            FROM booking b
            JOIN membercourse mc  ON mc.membercourseid = b.membercourseid
            JOIN classschedule s  ON s.scheduleid = b.scheduleid
            WHERE mc.memberid = :memberid
            """;

    public BookingStatsResponse getBookingStats(Integer memberid) {
        LocalDateTime now = LocalDateTime.now();
        MapSqlParameterSource params = new MapSqlParameterSource("memberid", memberid)
                .addValue("today", Date.valueOf(now.toLocalDate()))
                .addValue("now", Time.valueOf(now.toLocalTime().withNano(0)));
        // 沒有任何預約時 SUM 會是 NULL，getInt 會轉成 0
        return jdbc.queryForObject(SQL_BOOKING_STATS, params,
                (rs, i) -> new BookingStatsResponse(
                        rs.getInt("completed"),
                        rs.getInt("cancelled"),
                        rs.getInt("upcoming")));
    }

    /* ───────── 會員照片 ───────── */

    /** 更新照片網址，回傳舊的網址（讓呼叫的人刪掉舊檔案） */
    public String updateAvatarUrl(Integer memberid, String avatarurl) {
        MapSqlParameterSource params = new MapSqlParameterSource("memberid", memberid);
        List<String> old = jdbc.queryForList(
                "SELECT avatarurl FROM member WHERE memberid = :memberid", params, String.class);
        if (old.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "找不到會員資料");
        }
        jdbc.update("UPDATE member SET avatarurl = :avatarurl WHERE memberid = :memberid",
                params.addValue("avatarurl", avatarurl));
        return old.get(0);
    }

    private static LocalTime toLocalTime(Time t) {
        return t == null ? null : t.toLocalTime();
    }

    private static LocalDate toLocalDate(Date d) {
        return d == null ? null : d.toLocalDate();
    }

    private static String trim(String s) {
        return s == null ? null : s.trim();
    }
}
