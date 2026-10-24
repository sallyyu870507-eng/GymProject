package tw.gymproject.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import tw.gymproject.entity.Coach;
import tw.gymproject.entity.Member;

import java.util.List;
import java.util.Optional;


public interface CoachRepository extends JpaRepository<Coach, Integer> {
    //透過entity的關聯，用accountid找coachid
    Optional<Coach> findByAccount_Accountid(Integer accountid); //Optional只能是0個或1個

    //教練頁面的會員列表使用SQL語法查，一樣分兩層，先查出跟教練買過課程的學員，再查學員目前剩哪些這位教練的課
    //因為全部使用SQL查，需要加上countQuery幫忙計算符合條件EXIST的學員數，給pageable使用
    @Query(
            value = """
                      SELECT m.*
                      FROM member m
                      WHERE m.status = 'active'
                        AND EXISTS (
                            SELECT 1
                            FROM membercourse mc
                            WHERE mc.memberid = m.memberid
                              AND mc.coachid = :coachid
                       )
                        AND (
                         :keyword IS NULL
                         OR :keyword = ''
                         OR m.name LIKE '%' + :keyword + '%'
                         OR m.phone LIKE '%' + :keyword + '%'
                            OR m.memberno LIKE '%' + :keyword + '%'
                    )
                      ORDER BY m.memberid
                    """,
            countQuery = """
                      SELECT COUNT(*)
                      FROM member m
                      WHERE m.status = 'active'
                        AND EXISTS (
                            SELECT 1
                            FROM membercourse mc
                            WHERE mc.memberid = m.memberid
                              AND mc.coachid = :coachid
                        )
                        AND (
                         :keyword IS NULL
                         OR :keyword = ''
                         OR m.name LIKE '%' + :keyword + '%'
                         OR m.phone LIKE '%' + :keyword + '%'
                            OR m.memberno LIKE '%' + :keyword + '%'
                    )
                    """,
            nativeQuery = true
    )
    Page<Member> searchCoachMembers(
            @Param("coachid") Integer coachid,
            @Param("keyword") String keyword,
            Pageable pageable
    );

    //查當頁所有學員的課程
    @Query(value = """

            SELECT
                  mc.memberid,
            c.courseid,
                  c.coursename,
                  SUM(mc.remainingsessions) AS remainingsessions
               FROM membercourse mc
               JOIN course c
                   ON mc.courseid = c.courseid
               WHERE mc.coachid = :coachid
                 AND mc.memberid IN (:memberIds)
               GROUP BY
                   mc.memberid,
                   c.courseid,
                   c.coursename
               HAVING SUM(mc.remainingsessions) > 0
               ORDER BY
                   mc.memberid,
                   c.coursename
            """,
            nativeQuery = true)
    List<Object[]> findMemberCourses(
            @Param("coachid") Integer coachid,
            @Param("memberIds") List<Integer> memberIds
    );

    //編輯會員前先看會員是不是這位教練的學員，SQL語法類似if-else，只要查到任何資料就馬上回傳1否則0
    @Query(value = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM membercourse mc
                WHERE mc.memberid = :memberid
                  AND mc.coachid = :coachid
            ) THEN 1 ELSE 0 END
            """, nativeQuery = true)
    Integer existsCoachMember(
            @Param("memberid") Integer memberid,
            @Param("coachid") Integer coachid
    );

    // 教練管理：檢查編號是否重複
    boolean existsByCoachno(String coachno);

    boolean existsByCoachnoAndCoachidNot(String coachno, Integer coachid);

    // 學員端：只查詢啟用中的教練
    List<Coach> findByStatusOrderByCoachidAsc(String status);

    Optional<Coach> findByCoachidAndStatus(Integer coachid, String status);


}			