package tw.gymproject.service;

import tw.gymproject.dto.CourseCreateRequest;
import tw.gymproject.entity.Course;
import tw.gymproject.repository.CourseRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import org.springframework.data.domain.Sort;
import tw.gymproject.dto.CourseUpdateRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import tw.gymproject.dto.CourseStatusRequest;

@Service
public class CourseService {

    private final CourseRepository courseRepository;

    public CourseService(CourseRepository courseRepository) {
        this.courseRepository = courseRepository;
    }

    @Transactional
    public Course createCourse(CourseCreateRequest request) {

        Course course = new Course();

        course.setCoursename(request.getCoursename().trim());
        course.setCoursetype(request.getCoursetype().trim());
        course.setDescription(request.getDescription());
        course.setPrice(request.getPrice());

        course.setDurationmin(60);
        course.setStatus("active");

        return courseRepository.save(course);
    }

    @Transactional(readOnly = true)
    public List<Course> getAllCourses() {
        return courseRepository.findAll(
                Sort.by(Sort.Direction.ASC, "courseid")
        );
    }

    @Transactional
    public Course updateCourse(
            Integer courseid,
            CourseUpdateRequest request) {

        // 查詢要修改的課程
        Course course = courseRepository.findById(courseid)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "找不到此課程"));

        // 更新可修改的欄位
        course.setCoursename(request.getCoursename().trim());
        course.setCoursetype(request.getCoursetype().trim());
        course.setDescription(request.getDescription());
        course.setPrice(request.getPrice());

        return courseRepository.save(course);
    }

    @Transactional
    public Course updateCourseStatus(
            Integer courseid,
            CourseStatusRequest request) {

        Course course = courseRepository.findById(courseid)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "找不到此課程"));

        course.setStatus(request.getStatus());

        return courseRepository.save(course);
    }

    @Transactional(readOnly = true)
    public Course getCourseById(Integer courseid) {

        return courseRepository.findById(courseid)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "找不到此課程"));
    }
}