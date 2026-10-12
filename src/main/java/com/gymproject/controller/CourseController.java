package com.gymproject.controller;

import com.gymproject.dto.CourseCreateRequest;
import com.gymproject.entity.Course;
import com.gymproject.service.CourseService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import com.gymproject.entity.Course;
import org.springframework.web.bind.annotation.GetMapping;
import com.gymproject.dto.CourseUpdateRequest;
import com.gymproject.dto.CourseStatusRequest;

@RestController
@RequestMapping("/api/courses")
public class CourseController {

    private final CourseService courseService;

    public CourseController(CourseService courseService) {
        this.courseService = courseService;
    }

    @PostMapping
    public ResponseEntity<Course> createCourse(
            @Valid @RequestBody CourseCreateRequest request) {

        Course course = courseService.createCourse(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(course);
    }

    @GetMapping
    public ResponseEntity<List<Course>> getAllCourses() {
        return ResponseEntity.ok(courseService.getAllCourses());
    }

    @PutMapping("/{courseid}")
    public ResponseEntity<Course> updateCourse(
            @PathVariable("courseid") Integer courseid,
            @Valid @RequestBody CourseUpdateRequest request) {

        return ResponseEntity.ok(
                courseService.updateCourse(courseid, request)
        );
    }

    @PatchMapping("/{courseid}/status")
    public ResponseEntity<Course> updateCourseStatus(
            @PathVariable("courseid") Integer courseid,
            @Valid @RequestBody CourseStatusRequest request) {

        return ResponseEntity.ok(
                courseService.updateCourseStatus(courseid, request)
        );
    }

    @GetMapping("/{courseid}")
    public ResponseEntity<Course> getCourseById(
            @PathVariable("courseid") Integer courseid) {

        return ResponseEntity.ok(
                courseService.getCourseById(courseid)
        );
    }
}