package com.gymproject.dto;

import com.gymproject.entity.Course;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
public class StudentCourseDetailResponse {

    private final Integer courseid;
    private final String coursename;
    private final String coursetype;
    private final String description;
    private final Integer durationmin;
    private final BigDecimal price;

    public StudentCourseDetailResponse(Course course) {
        this.courseid = course.getCourseid();
        this.coursename = course.getCoursename();
        this.coursetype = course.getCoursetype();
        this.description = course.getDescription();
        this.durationmin = course.getDurationmin();
        this.price = course.getPrice();
    }
}