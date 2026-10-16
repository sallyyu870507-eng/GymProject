package tw.gymproject.repository;

import tw.gymproject.entity.Course;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CourseRepository extends JpaRepository<Course, Integer> {

    List<Course> findByStatusOrderByCourseidAsc(String status);

    Optional<Course> findByCourseidAndStatus(Integer courseid, String status);

}