package tw.gymproject.dto;

import tw.gymproject.entity.Course;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
public class StudentCourseListResponse {

    private final Integer courseid;
    private final String coursename;
    private final String coursetype;
    private final BigDecimal price;

    public StudentCourseListResponse(Course course) {
        this.courseid = course.getCourseid();
        this.coursename = course.getCoursename();
        this.coursetype = course.getCoursetype();
        this.price = course.getPrice();
    }
}