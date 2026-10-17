package tw.gymproject.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import tw.gymproject.entity.Member;
import tw.gymproject.entity.Useraccount;

@Repository
public interface MemberRepository extends JpaRepository<Member, Integer>{

	Optional<Member> findByAccount_Accountid(Integer accountid); //Optional只能是0個或1個
		
	//只抓某種狀態的會員
	List<Member> findByStatus(String status);
	//使用原生SQL
	//這邊只抓出剩餘課堂數、課程名稱，會員資料從Entity去抓之後分頁比較準
	String SQL_MEMBCOUR ="""
			    SELECT	mc.memberid,
				        c.coursename,
				        mc.remainingsessions
			    FROM membercourse mc
			    INNER JOIN course c
			    ON mc.courseid = c.courseid
			    WHERE mc.memberid IN (:memberIds)
			    AND mc.remainingsessions > 0
			""";
	
	@Query(value = SQL_MEMBCOUR, nativeQuery=true)
	List<Object[]> findMemberCourses(
			@Param("memberIds") List<Integer> memberid); //Service要給的參數
	
	//會員搜尋框
	//使用JPQL
	@Query("""
		    SELECT m FROM Member m
		    WHERE (:status = 'all' OR m.status = :status)
		    AND (
		        m.name LIKE CONCAT('%', :keyword, '%')
		        OR m.phone LIKE CONCAT('%', :keyword, '%')
		    )
		    """)
	Page<Member> searchMembers(
	    @Param("keyword") String keyword,
	    @Param("status") String status,
	    Pageable pageable
	);

	//給會員查詢分類狀態用
	Page<Member> findByStatus(
		    String status,
		    Pageable pageable
		);
	
}





/*一次在SQL裡抓出會員資料+剩餘課堂數+課程名稱，但不好做分頁因為一個會員可能會有多筆課程資料(會被算入分頁數))
直接用SQL抓出會員列表要看的所有資料再透過Service去分配
得到物件陣列，再用row[0],row[1]...取出實際內容
SELECT m.memberno, m.name, m.gender, m.phone, c.coursename, mc.remainingsessions
			FROM member m
			LEFT JOIN membercourse mc on m.memberid = mc.memberid
			LEFT JOIN course c on mc.courseid = c.courseid
			WHERE m.status = 'active'
			ORDER BY m.memberid
*/