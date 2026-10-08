package tw.gym.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import tw.gym.entity.Booking;

public interface BookingRepository
        extends JpaRepository<Booking, Integer> {
	
	//*會員端
	// 防呆機制(預防重複預約)
    // 查某個時段是否已經有 booked 的預約
    boolean existsByScheduleidAndBookingstatus(
            Integer scheduleid,
            String bookingstatus
    );

    //防呆機制(有剩餘課堂才能預約)
    //查 membercourse 的剩餘堂數
   
    @Query(value = """
            SELECT remainingsessions
            FROM membercourse
            WHERE membercourseid = :membercourseid
            """, nativeQuery = true)
    Integer findRemainingSessionsByMembercourseid(
            @Param("membercourseid") Integer membercourseid
    );

    //防呆機制(A會員拿相對應的課)
    //查 membercourse 對應的 courseid
    @Query(value = """
            SELECT courseid
            FROM membercourse
            WHERE membercourseid = :membercourseid
            """, nativeQuery = true)
    Integer findCourseidByMembercourseid(
            @Param("membercourseid") Integer membercourseid
    );
    
    //防呆機制(會員對應的教練)
    //查會員這筆購課紀錄綁定哪一位教練
    @Query(value = """
            SELECT coachid
            FROM membercourse
            WHERE membercourseid = :membercourseid
            """, nativeQuery = true)
    Integer findCoachidByMembercourseid(
            @Param("membercourseid") Integer membercourseid
    );
    
    //會員端
    /*1.查會員已購買，而且還有剩餘堂數的課程(登入顯示畫面)*/
    
    @Query(value = """
            SELECT
                mc.membercourseid,
                mc.courseid,
                c.coursename,
                mc.coachid,
                co.name,
                mc.remainingsessions
            FROM membercourse mc
            JOIN course c
                ON mc.courseid = c.courseid
            JOIN coach co
            	ON mc.coachid=co.coachid
            WHERE mc.memberid = :memberid
            AND mc.status = 'active'
            AND mc.remainingsessions > 0
            ORDER BY c.coursename
            """, nativeQuery = true)
    List<Object[]> findPurchasedCoursesByMemberid(
            @Param("memberid") Integer memberid
    );
    
    /*2.3.選已購課程跑出教練跟課程的資訊*/
    
    @Query(value = """
            SELECT
                mc.courseid,
                mc.coachid
            FROM membercourse mc
            WHERE mc.membercourseid = :membercourseid
            AND mc.memberid = :memberid
            AND mc.status = 'active'
            AND mc.remainingsessions > 0
            """, nativeQuery = true)
    List<Object[]> findCourseAndCoachByMembercourseidAndMemberid(
            @Param("membercourseid") Integer membercourseid,
            @Param("memberid") Integer memberid
    );
    
    
    /* 5.查預約成功頁需要的完整資料 */
    @Query(value = """
            SELECT
                b.bookingid,
                c.coursename,
                co.name,
                cs.classdate,
                cs.starttime,
                cs.endtime,
                cs.classroom,
                b.bookingstatus
            FROM booking b
            JOIN classschedule cs
                ON b.scheduleid = cs.scheduleid
            JOIN course c
                ON cs.courseid = c.courseid
            JOIN coach co
                ON cs.coachid = co.coachid
            WHERE b.bookingid = :bookingid
            """, nativeQuery = true)
    List<Object[]> findBookingResponseByBookingid(
            @Param("bookingid") Integer bookingid
    );
}