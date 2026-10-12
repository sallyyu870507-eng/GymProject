package com.gymproject.controller;

import com.gymproject.dto.CoachCoursesRequest;
import com.gymproject.service.CoachCourseService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import com.gymproject.entity.Course;

@RestController
@RequestMapping("/api/coaches")
public class CoachCourseController {

    private final CoachCourseService coachCourseService;

    public CoachCourseController(
            CoachCourseService coachCourseService) {
        this.coachCourseService = coachCourseService;
    }

    @PutMapping("/{coachid}/courses")
    public ResponseEntity<Map<String, Object>> setCourses(
            @PathVariable("coachid") Integer coachid,
            @Valid @RequestBody CoachCoursesRequest request) {

        List<Integer> courseids =
                coachCourseService.setCourses(coachid, request);

        return ResponseEntity.ok(Map.of(
                "coachid", coachid,
                "courseids", courseids
        ));
    }

    @GetMapping("/{coachid}/courses")
    public ResponseEntity<List<Course>> getCoursesByCoach(
            @PathVariable("coachid") Integer coachid) {

        return ResponseEntity.ok(
                coachCourseService.getCoursesByCoach(coachid)
        );
    }
}