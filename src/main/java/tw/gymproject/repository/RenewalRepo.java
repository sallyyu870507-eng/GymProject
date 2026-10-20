package tw.gymproject.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import tw.gymproject.entity.Renewal;

import java.util.List;

public interface RenewalRepo extends JpaRepository<Renewal, Integer> {

    // 查某個 MemberCourse 的所有續約紀錄，最新的排前面
    List<Renewal> findByMemberCourse_MembercourseidOrderByRenewaldateDesc(
            Integer membercourseid
    );
    // 新增：工作台查目前教練各來源方案的續約關係
    @Query("""
            select r
            from Renewal r
            join fetch r.memberCourse source
            join fetch r.newMemberCourse target
            join fetch target.course
            where source.coach.coachid = :coachId
            order by r.renewaldate desc, r.renewalid desc
            """)
    List<Renewal> findWorkbenchRenewals(
            @Param("coachId") Integer coachId
    );
}