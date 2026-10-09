package tw.gymproject.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tw.gymproject.entity.FollowUp;

import java.util.List;

public interface FollowUpRepo extends JpaRepository<FollowUp, Integer> {

    // 查某教練的某種追蹤狀態
    List<FollowUp> findByCoach_CoachidAndStatus(
            Integer coachid,
            String status
    );

    // 查某個 MemberCourse 的所有追蹤紀錄，最新的排前面
    List<FollowUp> findByMemberCourse_MembercourseidOrderByCreatedateDesc(
            Integer membercourseid
    );
}