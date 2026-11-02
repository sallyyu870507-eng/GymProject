package tw.gymproject.repository;

import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public class RenewalWorkbenchRepo {

    private final NamedParameterJdbcTemplate jdbc;

    public RenewalWorkbenchRepo(
            NamedParameterJdbcTemplate jdbc
    ) {
        this.jdbc = jdbc;
    }

    /*
     * 共同查詢：
     * 1. 限定登入教練的方案
     * 2. 計算同組活動基準
     * 3. 取得最新跟進、是否續約
     * 4. 計算四種分類
     */
    private static final String BASE_SQL = """
            WITH Authorized AS (
                SELECT mc.*, m.name
                FROM dbo.membercourse mc
                JOIN dbo.member m
                  ON m.memberid = mc.memberid
                WHERE mc.coachid = :coachId
            ),
            FirstPurchase AS (
                SELECT memberid, courseid, coachid,
                       MIN(purchasedate) AS firstPurchaseDate
                FROM Authorized
                WHERE purchasedate <= :asOfDate
                GROUP BY memberid, courseid, coachid
            ),
            LastPresent AS (
                SELECT mc.memberid, mc.courseid, mc.coachid,
                       MAX(s.classdate) AS lastPresentDate
                FROM Authorized mc
                JOIN dbo.booking b
                  ON b.membercourseid = mc.membercourseid
                JOIN dbo.attendance a
                  ON a.bookingid = b.bookingid
                JOIN dbo.classschedule s
                  ON s.scheduleid = b.scheduleid
                WHERE a.attendancestatus = N'PRESENT'
                  AND LOWER(b.bookingstatus) <> N'cancelled'
                  AND s.classdate <= :asOfDate
                GROUP BY mc.memberid, mc.courseid, mc.coachid
            ),
            Facts AS (
                SELECT mc.*,
                       COALESCE(
                           lp.lastPresentDate,
                           fp.firstPurchaseDate
                       ) AS baselineDate,
                       CASE WHEN EXISTS (
                           SELECT 1
                           FROM dbo.renewal r
                           JOIN dbo.membercourse target
                             ON target.membercourseid =
                                r.newmembercourseid
                           WHERE r.membercourseid =
                                 mc.membercourseid
                       ) THEN 1 ELSE 0 END AS hasRenewed,
                       latest.followupid AS latestFollowupId,
                       latest.status AS latestFollowupStatus
                FROM Authorized mc
                LEFT JOIN FirstPurchase fp
                  ON fp.memberid = mc.memberid
                 AND fp.courseid = mc.courseid
                 AND fp.coachid = mc.coachid
                LEFT JOIN LastPresent lp
                  ON lp.memberid = mc.memberid
                 AND lp.courseid = mc.courseid
                 AND lp.coachid = mc.coachid
                OUTER APPLY (
                    SELECT TOP (1) f.followupid, f.status
                    FROM dbo.followup f
                    WHERE f.membercourseid = mc.membercourseid
                    ORDER BY
                        CASE WHEN f.createdate IS NULL
                             THEN 1 ELSE 0 END,
                        f.createdate DESC,
                        f.followupid DESC
                ) latest
            ),
            Tagged AS (
                SELECT Facts.*,
                       CASE WHEN remainingsessions BETWEEN 1 AND 5
                                  AND hasRenewed = 0
                            THEN 1 ELSE 0 END AS highPriority,
                       CASE WHEN remainingsessions BETWEEN 6 AND 10
                                  AND hasRenewed = 0
                            THEN 1 ELSE 0 END AS upcoming,
                       CASE WHEN remainingsessions > 0
                                  AND DATEDIFF(
                                      day, baselineDate, :asOfDate
                                  ) >= 14
                            THEN 1 ELSE 0 END AS longAbsent,
                       CASE WHEN remainingsessions = 0
                                  AND hasRenewed = 0
                            THEN 1 ELSE 0 END AS completed
                FROM Facts
            ),
            Classified AS (
                SELECT Tagged.*,
                       CASE WHEN highPriority = 1
                                  OR upcoming = 1
                                  OR longAbsent = 1
                                  OR completed = 1
                            THEN 1 ELSE 0 END AS tracking
                FROM Tagged
            )
            """;

    private static final String FILTER_SQL = """
            WHERE (:scope = 'ALL_PLANS' OR tracking = 1)
              AND (
                  :keyword = ''
                  OR CHARINDEX(:keyword, name) > 0
              )
              AND (
                  :category = 'ALL'
                  OR (:category = 'HIGH_PRIORITY'
                      AND highPriority = 1)
                  OR (:category = 'UPCOMING'
                      AND upcoming = 1)
                  OR (:category = 'LONG_ABSENT'
                      AND longAbsent = 1)
                  OR (:category = 'COMPLETED'
                      AND completed = 1)
              )
              AND (
                  :followupStatus = 'ALL'
                  OR (
                      :followupStatus = 'NOT_CONTACTED'
                      AND latestFollowupId IS NULL
                  )
                  OR (
                      latestFollowupId IS NOT NULL
                      AND latestFollowupStatus = :followupStatus
                  )
              )
            """;

    // 全部授權方案的統計，不套列表篩選
    public CountsResult findCounts(
            Integer coachId,
            LocalDate asOfDate
    ) {
        String sql = BASE_SQL + """
                SELECT COUNT_BIG(*) AS authorizedPlanCount,
                       COALESCE(SUM(CAST(tracking AS bigint)), 0)
                           AS trackingPlanCount,
                       COALESCE(SUM(CAST(highPriority AS bigint)), 0)
                           AS highPriority,
                       COALESCE(SUM(CAST(upcoming AS bigint)), 0)
                           AS upcoming,
                       COALESCE(SUM(CAST(longAbsent AS bigint)), 0)
                           AS longAbsent,
                       COALESCE(SUM(CAST(completed AS bigint)), 0)
                           AS completed
                FROM Classified
                """;

        return jdbc.queryForObject(
                sql,
                baseParams(coachId, asOfDate),
                (rs, rowNum) -> new CountsResult(
                        rs.getLong("authorizedPlanCount"),
                        rs.getLong("trackingPlanCount"),
                        rs.getLong("highPriority"),
                        rs.getLong("upcoming"),
                        rs.getLong("longAbsent"),
                        rs.getLong("completed")
                )
        );
    }

    // 所有符合篩選的方案數，不是這一頁的筆數
    public long countFiltered(
            Integer coachId,
            LocalDate asOfDate,
            String scope,
            String keyword,
            String category,
            String followupStatus
    ) {
        String sql = BASE_SQL
                + " SELECT COUNT_BIG(*) FROM Classified "
                + FILTER_SQL;

        Long count = jdbc.queryForObject(
                sql,
                filterParams(
                        coachId, asOfDate, scope, keyword,
                        category, followupStatus
                ),
                Long.class
        );

        if (count == null) {
            throw new IllegalStateException("工作台筆數查詢沒有結果");
        }

        return count;
    }

    // 依穩定順序，在資料庫分頁，只取這一頁的方案 ID
    public List<Integer> findPageIds(
            Integer coachId,
            LocalDate asOfDate,
            String scope,
            String keyword,
            String category,
            String followupStatus,
            long offset
    ) {
        String sql = BASE_SQL
                + " SELECT membercourseid FROM Classified "
                + FILTER_SQL
                + """
                 ORDER BY purchasedate DESC, membercourseid DESC
                 OFFSET :offset ROWS
                 FETCH NEXT 10 ROWS ONLY
                """;

        MapSqlParameterSource params = filterParams(
                coachId, asOfDate, scope, keyword,
                category, followupStatus
        ).addValue("offset", offset);

        return jdbc.query(
                sql,
                params,
                (rs, rowNum) -> rs.getInt("membercourseid")
        );
    }

    private MapSqlParameterSource baseParams(
            Integer coachId,
            LocalDate asOfDate
    ) {
        return new MapSqlParameterSource()
                .addValue("coachId", coachId)
                .addValue(
                        "asOfDate",
                        java.sql.Date.valueOf(asOfDate)
                );
    }

    private MapSqlParameterSource filterParams(
            Integer coachId,
            LocalDate asOfDate,
            String scope,
            String keyword,
            String category,
            String followupStatus
    ) {
        return baseParams(coachId, asOfDate)
                .addValue("scope", scope)
                .addValue("keyword", keyword)
                .addValue("category", category)
                .addValue("followupStatus", followupStatus);
    }

    public record CountsResult(
            long authorizedPlanCount,
            long trackingPlanCount,
            long highPriority,
            long upcoming,
            long longAbsent,
            long completed
    ) {
    }
}