package tw.gymproject.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import tw.gymproject.entity.Course;

public interface CourseRepo extends JpaRepository<Course, Integer>{

	List<Course> findByStatusOrderByCoursenameAsc(
            String status);
}
