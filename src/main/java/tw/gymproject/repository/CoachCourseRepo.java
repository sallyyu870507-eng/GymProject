package tw.gymproject.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import tw.gymproject.entity.Coach;
import tw.gymproject.entity.CoachCourse;
import tw.gymproject.entity.CoachCourseId;

public interface CoachCourseRepo extends JpaRepository<CoachCourse, CoachCourseId>{

    @Query("""
        SELECT c
        FROM CoachCourse cc
        JOIN Coach c
            ON cc.id.coachid = c.coachid
        WHERE cc.id.courseid = :courseid
          AND c.status = 'active'
        ORDER BY c.name
    """)
    List<Coach> findCoachesByCourseId(
            @Param("courseid") Integer courseid);

    List<CoachCourse> findById_Coachid(Integer coachid);

}
