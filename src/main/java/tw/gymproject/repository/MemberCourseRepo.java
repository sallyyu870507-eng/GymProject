package tw.gymproject.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tw.gymproject.entity.MemberCourse;

import java.util.List;

public interface MemberCourseRepo extends JpaRepository<MemberCourse, Integer> {

    // 某教練全部 MemberCourse
    List<MemberCourse> findByCoach_Coachid(Integer coachid);

    // 某教練低堂數
    List<MemberCourse> findByCoach_CoachidAndRemainingsessionsLessThanEqual(
            Integer coachid,
            Integer remainingsessions
    );

    // 某教練剩餘堂數 = 指定值
    List<MemberCourse> findByCoach_CoachidAndRemainingsessions(
            Integer coachid,
            Integer remainingsessions
    );

    // 某教練 + 課程狀態
    List<MemberCourse> findByCoach_CoachidAndStatus(
            Integer coachid,
            String status
    );
}