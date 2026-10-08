package tw.gym.repository;


import java.time.LocalDate;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import tw.gym.entity.ClassSchedule;


public interface ClassScheduleRepository
	extends JpaRepository<ClassSchedule, Integer>{
	

    //會員端
    /*2.依課程+教練查可以預約的日期*/
    @Query(value = """
    		SELECT DISTINCT cs.classdate
    		FROM classschedule cs
    		WHERE cs.courseid = :courseid
    		AND cs.coachid = :coachid
    		AND cs.status ='open'
    		AND NOT EXISTS(
    			SELECT 1
    			FROM booking b
    			WHERE b.scheduleid= cs.scheduleid
    			AND b.bookingstatus = 'booked'
    		)
    		ORDER BY cs.classdate
    		""", nativeQuery = true)
    
    	List<java.sql.Date> findAvailableDates(
    			@Param("courseid") Integer courseid,
    			@Param("coachid") Integer coachid
    			);
    
    /* 3.查某課程 + 教練 + 日期的全部時段 */
    /*case如果...不然...否則...*/
    @Query(value = """
            SELECT
                cs.scheduleid,
                cs.starttime,
                cs.endtime,
                CASE
                    WHEN cs.status <> 'open' THEN cs.status
                    WHEN EXISTS (
                        SELECT 1
                        FROM booking b
                        WHERE b.scheduleid = cs.scheduleid
                        AND b.bookingstatus = 'booked'
                    ) THEN 'booked'
                    ELSE 'available'
                END AS slotstatus
            FROM classschedule cs
            WHERE cs.courseid = :courseid
            AND cs.coachid = :coachid
            AND cs.classdate = :classdate
            ORDER BY cs.starttime
            """, nativeQuery = true)
    List<Object[]> findScheduleOptions(
            @Param("courseid") Integer courseid,
            @Param("coachid") Integer coachid,
            @Param("classdate") LocalDate classdate
    );
    
    /*教練端*/
    /* 1.查教練某一天已被預約的課表 */
    @Query(value = """
    		SELECT 
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
    		AND b.bookingstatus ='booked'
    		ORDER BY cs.starttime
    		""",nativeQuery = true)
    List<Object[]> findBookedSchedulesByCoachAndDate(
    		@Param("coachid") Integer coachid,
    		@Param("classdate") LocalDate classdate
    		);
    
    /*2.教練某一天的課程數*/
    @Query(value="""
    		SELECT COUNT(*)
    		FROM classschedule cs
    		JOIN booking b
    			ON cs.scheduleid = b.scheduleid
    		WHERE cs.coachid= :coachid
    		AND cs.classdate= :classdate
    		AND b.bookingstatus ='booked'
    		""",nativeQuery = true)
    Integer countTodayCourses(
    		@Param("coachid") Integer coachid,
    		@Param("classdate") LocalDate classdate);
    
    /*3.教練某一天的不重複學生數*/
    @Query(value="""
    		SELECT COUNT(DISTINCT mc.memberid)
    		FROM classschedule cs
    		JOIN booking b
    			ON cs.scheduleid = b.scheduleid
    		JOIN membercourse mc
    			ON b.membercourseid = mc.membercourseid
    		WHERE cs.coachid= :coachid
     		AND cs.classdate= :classdate
    		AND b.bookingstatus= 'booked'
    		""",nativeQuery = true)
    Integer countTodayStudent(
    		@Param("coachid") Integer coachid,
    		@Param("classdate") LocalDate classdate);
    
    
    /*管理員端*/
    /* 管理員查某一天全館所有教練的排課狀態 */
    @Query(value = """
    		SELECT
    			cs.scheduleid,
    			cs.coachid,
    			co.name AS coachname,
    			cs.classdate,
    			cs.starttime,
    			cs.endtime,
    		CASE 
    		WHEN cs.status <> 'open' THEN cs.status
    		WHEN EXISTS(
    			SELECT 1
    			FROM booking b2
    			WHERE b2.scheduleid = cs.scheduleid
    			AND b2.bookingstatus='booked'
    		)THEN 'booked'
    		ELSE 'available'
    		END AS displaystatus,
    		
    		m.name AS membername,
    		c.coursename
    		
    		FROM classschedule cs
    		JOIN coach co
    			ON cs.coachid= co.coachid
    		LEFT JOIN booking b
    			ON b.scheduleid= cs.scheduleid
    			AND b.bookingstatus= 'booked'
    		LEFT JOIN membercourse mc
    			ON b.membercourseid =mc.membercourseid
    		LEFT JOIN member m
    			ON mc.memberid =m.memberid
    		LEFT JOIN course c
    			ON cs.courseid =c.courseid
    		WHERE cs.classdate= :classdate
    		ORDER BY 
    			cs.starttime,
    			cs.coachid
    		""",nativeQuery = true)
			     /*如果這個時段本來就不是 open
					→ 直接顯示原本狀態
				否則，如果這個時段已經有人 booked
					→ 顯示 booked
				否則
					→ 顯示 available*/
    List<Object[]> findAdminSchedulesByDate(
    		@Param("classdate") LocalDate classdate);
    
	    /* 管理員取得所有教練 */
	    @Query(value = """
	            SELECT
	                coachid,
	                name
	            FROM coach
	            ORDER BY coachid
	            """, nativeQuery = true)
	    List<Object[]> findAllCoachesForAdmin();
}
