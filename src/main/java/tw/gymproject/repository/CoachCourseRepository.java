package tw.gymproject.repository;

import tw.gymproject.entity.CoachCourse;
import tw.gymproject.entity.CoachCourseId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CoachCourseRepository extends JpaRepository<CoachCourse, CoachCourseId> {

    List<CoachCourse> findById_Coachid(Integer coachid);

}