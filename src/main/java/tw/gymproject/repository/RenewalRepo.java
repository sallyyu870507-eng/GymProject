package tw.gymproject.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tw.gymproject.entity.Renewal;

import java.util.List;

public interface RenewalRepo extends JpaRepository<Renewal, Integer> {

    // 查某個 MemberCourse 的所有續約紀錄，最新的排前面
    List<Renewal> findByMemberCourse_MembercourseidOrderByRenewaldateDesc(
            Integer membercourseid
    );
}