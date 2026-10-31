package tw.gymproject.repository;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import tw.gymproject.entity.Membercourse;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface MemberCourseRepo
        extends JpaRepository<Membercourse, Integer> {

    // 某教練全部方案
    List<Membercourse> findByCoach_Coachid(Integer coachid);

    // 某教練剩餘堂數小於或等於指定值
    List<Membercourse> findByCoach_CoachidAndRemainingsessionsLessThanEqual(
            Integer coachid,
            Integer remainingsessions
    );

    // 某教練剩餘堂數等於指定值
    List<Membercourse> findByCoach_CoachidAndRemainingsessions(
            Integer coachid,
            Integer remainingsessions
    );

    // 某教練、指定方案狀態
    List<Membercourse> findByCoach_CoachidAndStatus(
            Integer coachid,
            String status
    );

    // 更新堂數前鎖定方案。
    // 必須在 Service 的 @Transactional 方法內呼叫。
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select mc
            from Membercourse mc
            where mc.membercourseid = :memberCourseId
            """)
    Optional<Membercourse> findByIdForUpdate(
            @Param("memberCourseId") Integer memberCourseId
    );

    // 同會員、同課程、同教練，截至查詢日的最早購買日
    @Query("""
            select
                mc.member.memberid as memberId,
                mc.course.courseid as courseId,
                mc.coach.coachid as coachId,
                min(mc.purchasedate) as firstPurchaseDate
            from Membercourse mc
            where mc.coach.coachid = :coachId
              and mc.purchasedate <= :asOfDate
            group by
                mc.member.memberid,
                mc.course.courseid,
                mc.coach.coachid
            """)
    List<CourseFirstPurchase> findCourseFirstPurchaseDates(
            @Param("coachId") Integer coachId,
            @Param("asOfDate") LocalDate asOfDate
    );

    // 讀取指定方案的工作台資料，限制為登入教練的方案
    @Query("""
            select mc
            from Membercourse mc
            join fetch mc.member
            join fetch mc.course
            join fetch mc.coach
            where mc.coach.coachid = :coachId
              and mc.membercourseid in :planIds
            order by mc.purchasedate desc,
                     mc.membercourseid desc
            """)
    List<Membercourse> findWorkbenchPlansByIds(
            @Param("coachId") Integer coachId,
            @Param("planIds") List<Integer> planIds
    );

    // 接收最早購買日的查詢結果，不是資料表
    interface CourseFirstPurchase {

        Integer getMemberId();

        Integer getCourseId();

        Integer getCoachId();

        LocalDate getFirstPurchaseDate();
    }

    // 方案詳情：同時取得會員、課程與教練
    @Query("""
            select mc
            from Membercourse mc
            join fetch mc.member
            join fetch mc.course
            join fetch mc.coach
            where mc.membercourseid = :memberCourseId
            """)
    Optional<Membercourse> findOverviewById(
            @Param("memberCourseId") Integer memberCourseId
    );
}