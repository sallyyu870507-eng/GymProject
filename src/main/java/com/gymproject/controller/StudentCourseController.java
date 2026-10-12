package com.gymproject.controller;

import com.gymproject.dto.StudentCourseDetailResponse;
import com.gymproject.dto.StudentCourseListResponse;
import com.gymproject.service.StudentCourseService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/student/courses")
public class StudentCourseController {

    private final StudentCourseService studentCourseService;

    public StudentCourseController(
            StudentCourseService studentCourseService) {
        this.studentCourseService = studentCourseService;
    }

    @GetMapping
    public ResponseEntity<List<StudentCourseListResponse>>
    getCourses() {

        return ResponseEntity.ok(
                studentCourseService.getCourses()
        );
    }

    @GetMapping("/{courseid}")
    public ResponseEntity<StudentCourseDetailResponse>
    getCourseById(
            @PathVariable("courseid") Integer courseid) {

        return ResponseEntity.ok(
                studentCourseService.getCourseById(courseid)
        );
    }
}