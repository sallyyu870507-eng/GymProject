package tw.gymproject.service;

import java.sql.Date;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.List;
import java.util.TreeMap;

import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;

import tw.gymproject.dto.member.MemberInBodyResponse;
import tw.gymproject.dto.member.MemberProfileResponse;
import tw.gymproject.dto.member.WeeklyAttendanceResponse;
import tw.gymproject.exception.ResourceNotFoundException;

/**
 * 會員端 Dashboard 用的唯讀查詢：個人資料、每週出席次數、InBody 紀錄。
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
            throw new ResourceNotFoundException("找不到會員資料");
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

    private static LocalDate toLocalDate(Date d) {
        return d == null ? null : d.toLocalDate();
    }

    private static String trim(String s) {
        return s == null ? null : s.trim();
    }
}
