package tw.gymproject.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import tw.gymproject.entity.Course;
import java.util.Optional;

public interface CourseRepo extends JpaRepository<Course, Integer>{

	List<Course> findByStatusOrderByCoursenameAsc(
            String status);

	List<Course> findByStatusOrderByCourseidAsc(String status);

	Optional<Course> findByCourseidAndStatus(Integer courseid, String status);
}
