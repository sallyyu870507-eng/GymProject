package tw.gymproject.service;

import tw.gymproject.dto.StudentCourseDetailResponse;
import tw.gymproject.dto.StudentCourseListResponse;
import tw.gymproject.entity.Course;
import tw.gymproject.repository.CourseRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class StudentCourseService {

    private final CourseRepository courseRepository;

    public StudentCourseService(CourseRepository courseRepository) {
        this.courseRepository = courseRepository;
    }

    @Transactional(readOnly = true)
    public List<StudentCourseListResponse> getCourses() {

        return courseRepository
                .findByStatusOrderByCourseidAsc("active")
                .stream()
                .map(StudentCourseListResponse::new)
                .toList();
    }

    @Transactional(readOnly = true)
    public StudentCourseDetailResponse getCourseById(
            Integer courseid) {

        Course course = courseRepository
                .findByCourseidAndStatus(courseid, "active")
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "此課程已下架或不存在"));

        return new StudentCourseDetailResponse(course);
    }
}