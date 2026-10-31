package tw.gymproject.repository;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import tw.gymproject.entity.ClassSchedule;


public interface ClassScheduleRepository
        extends JpaRepository<ClassSchedule, Integer> {


    // =====================================================
    // 會員端
    // =====================================================


    /*
     * 1. 依課程 + 教練查可以預約的日期
     *
     * 會員規則：
     * 今天不能預約
     * 只能預約明天以後
     */
    @Query(value = """
            SELECT DISTINCT
                cs.classdate

            FROM classschedule cs

            WHERE cs.courseid = :courseid
            AND cs.coachid = :coachid
            AND cs.status = 'open'

            AND cs.classdate > CAST(GETDATE() AS DATE)

            AND NOT EXISTS (
                SELECT 1

                FROM booking b

                WHERE b.scheduleid = cs.scheduleid
                AND b.bookingstatus = 'booked'
            )

            ORDER BY cs.classdate
            """, nativeQuery = true)
    List<java.sql.Date> findAvailableDates(
            @Param("courseid") Integer courseid,
            @Param("coachid") Integer coachid
    );


    /*
     * 2. 查某課程 + 教練 + 日期的全部時段
     *
     * 會員規則：
     * 只能查明天以後
     *
     * status：
     * available
     * booked
     * 或 classschedule 原本的 status
     */
    @Query(value = """
            SELECT
                cs.scheduleid,
                cs.starttime,
                cs.endtime,

                CASE

                    WHEN cs.status <> 'open'
                        THEN cs.status

                    WHEN EXISTS (
                        SELECT 1

                        FROM booking b

                        WHERE b.scheduleid = cs.scheduleid
                        AND b.bookingstatus = 'booked'
                    )
                        THEN 'booked'

                    ELSE 'available'

                END AS slotstatus

            FROM classschedule cs

            WHERE cs.courseid = :courseid
            AND cs.coachid = :coachid
            AND cs.classdate = :classdate

            AND cs.classdate > CAST(GETDATE() AS DATE)

            ORDER BY cs.starttime
            """, nativeQuery = true)
    List<Object[]> findScheduleOptions(
            @Param("courseid") Integer courseid,
            @Param("coachid") Integer coachid,
            @Param("classdate") LocalDate classdate
    );


    // =====================================================
    // 教練端
    // =====================================================


    /*
     * 1. 查教練某一天已被預約的課表
     */
    @Query(value = """
            SELECT
                b.bookingid,
                cs.scheduleid,
                c.coursename,
                m.name,
                cs.starttime,
                cs.endtime

            FROM classschedule cs

            JOIN booking b
                ON cs.scheduleid = b.scheduleid

            JOIN membercourse mc
                ON b.membercourseid = mc.membercourseid

            JOIN member m
                ON mc.memberid = m.memberid

            JOIN course c
                ON cs.courseid = c.courseid

            WHERE cs.coachid = :coachid
            AND cs.classdate = :classdate
            AND b.bookingstatus = 'booked'

            ORDER BY cs.starttime
            """, nativeQuery = true)
    List<Object[]> findBookedSchedulesByCoachAndDate(
            @Param("coachid") Integer coachid,
            @Param("classdate") LocalDate classdate
    );


    /*
     * 2. 教練某一天課程數
     */
    @Query(value = """
            SELECT COUNT(*)

            FROM classschedule cs

            JOIN booking b
                ON cs.scheduleid = b.scheduleid

            WHERE cs.coachid = :coachid
            AND cs.classdate = :classdate
            AND b.bookingstatus = 'booked'
            """, nativeQuery = true)
    Integer countTodayCourses(
            @Param("coachid") Integer coachid,
            @Param("classdate") LocalDate classdate
    );


    /*
     * 3. 教練某一天的不重複學生數
     */
    @Query(value = """
            SELECT COUNT(
                DISTINCT mc.memberid
            )

            FROM classschedule cs

            JOIN booking b
                ON cs.scheduleid = b.scheduleid

            JOIN membercourse mc
                ON b.membercourseid = mc.membercourseid

            WHERE cs.coachid = :coachid
            AND cs.classdate = :classdate
            AND b.bookingstatus = 'booked'
            """, nativeQuery = true)
    Integer countTodayStudent(
            @Param("coachid") Integer coachid,
            @Param("classdate") LocalDate classdate
    );


    // =====================================================
    // 教練修改預約
    // =====================================================


    /*
     * 4. 教練修改預約：
     * 查今天以後有哪些日期有可用時段
     *
     * 和會員差異：
     *
     * 會員：
     * classdate > 今天
     *
     * 教練：
     * classdate >= 今天
     *
     * 因為教練今天未開始的課程仍然可以修改。
     */
    @Query(value = """
            SELECT DISTINCT
                cs.classdate

            FROM classschedule cs

            WHERE cs.courseid = :courseid
            AND cs.coachid = :coachid
            AND cs.status = 'open'

            AND cs.classdate >= CAST(GETDATE() AS DATE)

            AND NOT EXISTS (
                SELECT 1

                FROM booking b

                WHERE b.scheduleid = cs.scheduleid
                AND b.bookingstatus = 'booked'
            )

            ORDER BY cs.classdate
            """, nativeQuery = true)
    List<java.sql.Date> findCoachRescheduleAvailableDates(
            @Param("courseid") Integer courseid,
            @Param("coachid") Integer coachid
    );


    /*
     * 5. 教練修改預約：
     * 查指定日期的全部時段
     *
     * 今天也可以查。
     *
     * 今天已經過開始時間的時段，
     * Repository 先照正常狀態回傳，
     * BookingCoachService 再依現在時間
     * 將它改成 closed。
     */
    @Query(value = """
            SELECT
                cs.scheduleid,
                cs.starttime,
                cs.endtime,

                CASE

                    WHEN cs.status <> 'open'
                        THEN cs.status

                    WHEN EXISTS (
                        SELECT 1

                        FROM booking b

                        WHERE b.scheduleid = cs.scheduleid
                        AND b.bookingstatus = 'booked'
                    )
                        THEN 'booked'

                    ELSE 'available'

                END AS slotstatus

            FROM classschedule cs

            WHERE cs.courseid = :courseid
            AND cs.coachid = :coachid
            AND cs.classdate = :classdate

            AND cs.classdate >= CAST(GETDATE() AS DATE)

            ORDER BY cs.starttime
            """, nativeQuery = true)
    List<Object[]> findCoachRescheduleScheduleOptions(
            @Param("courseid") Integer courseid,
            @Param("coachid") Integer coachid,
            @Param("classdate") LocalDate classdate
    );


    // =====================================================
    // 管理員端
    // =====================================================


    /*
     * 1. 管理員查某一天
     * 全館所有教練排課狀態
     */
    @Query(value = """
            SELECT
                cs.scheduleid,
                cs.coachid,
                co.name AS coachname,
                cs.classdate,
                cs.starttime,
                cs.endtime,

                CASE

                    WHEN cs.status <> 'open'
                        THEN cs.status

                    WHEN EXISTS (
                        SELECT 1

                        FROM booking b2

                        WHERE b2.scheduleid = cs.scheduleid
                        AND b2.bookingstatus = 'booked'
                    )
                        THEN 'booked'

                    ELSE 'available'

                END AS displaystatus,

                m.name AS membername,
                c.coursename

            FROM classschedule cs

            JOIN coach co
                ON cs.coachid = co.coachid

            LEFT JOIN booking b
                ON b.scheduleid = cs.scheduleid
                AND b.bookingstatus = 'booked'

            LEFT JOIN membercourse mc
                ON b.membercourseid = mc.membercourseid

            LEFT JOIN member m
                ON mc.memberid = m.memberid

            LEFT JOIN course c
                ON cs.courseid = c.courseid

            WHERE cs.classdate = :classdate

            ORDER BY
                cs.starttime,
                cs.coachid
            """, nativeQuery = true)
    List<Object[]> findAdminSchedulesByDate(
            @Param("classdate") LocalDate classdate
    );


    /*
     * 2. 管理員取得所有教練
     */
    @Query(value = """
            SELECT
                coachid,
                name

            FROM coach

            ORDER BY coachid
            """, nativeQuery = true)
    List<Object[]> findAllCoachesForAdmin();

}