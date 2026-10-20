package tw.gymproject.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tw.gymproject.entity.CoachCourse;
import tw.gymproject.entity.CoachCourseId;

import java.util.List;

public interface CoachCourseRepository
        extends JpaRepository<CoachCourse, CoachCourseId> {

    List<CoachCourse> findById_Coachid(Integer coachid);
}