package tw.gymproject.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tw.gymproject.entity.Course;

import java.util.List;
import java.util.Optional;

public interface CourseRepository
        extends JpaRepository<Course, Integer> {

    // 查指定狀態的課程，依課程 ID 排序
    List<Course> findByStatusOrderByCourseidAsc(String status);

    // 查指定課程，並確認狀態
    Optional<Course> findByCourseidAndStatus(
            Integer courseid,
            String status
    );
}