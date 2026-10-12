package com.gymproject.controller;

import com.gymproject.dto.CoachCreateRequest;
import com.gymproject.entity.Coach;
import com.gymproject.service.CoachService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import com.gymproject.entity.Coach;
import org.springframework.web.bind.annotation.GetMapping;
import com.gymproject.dto.CoachUpdateRequest;
import com.gymproject.dto.CoachStatusRequest;

@RestController
@RequestMapping("/api/coaches")
public class CoachController {

    private final CoachService coachService;

    public CoachController(CoachService coachService) {
        this.coachService = coachService;
    }

    @PostMapping
    public ResponseEntity<Coach> createCoach(
            @Valid @RequestBody CoachCreateRequest request) {

        Coach coach = coachService.createCoach(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(coach);
    }

    @GetMapping
    public ResponseEntity<List<Coach>> getAllCoaches() {
        return ResponseEntity.ok(coachService.getAllCoaches());
    }

    @PutMapping("/{coachid}")
    public ResponseEntity<Coach> updateCoach(
            @PathVariable("coachid") Integer coachid,
            @Valid @RequestBody CoachUpdateRequest request) {

        return ResponseEntity.ok(
                coachService.updateCoach(coachid, request)
        );
    }

    @PatchMapping("/{coachid}/status")
    public ResponseEntity<Coach> updateCoachStatus(
            @PathVariable("coachid") Integer coachid,
            @Valid @RequestBody CoachStatusRequest request) {

        return ResponseEntity.ok(
                coachService.updateCoachStatus(coachid, request)
        );
    }

    @GetMapping("/{coachid}")
    public ResponseEntity<Coach> getCoachById(
            @PathVariable("coachid") Integer coachid) {

        return ResponseEntity.ok(
                coachService.getCoachById(coachid)
        );
    }
}