package tw.gymproject.controller;

import tw.gymproject.dto.CoachCreateRequest;
import tw.gymproject.entity.Coach;
import tw.gymproject.service.CoachManagementService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import tw.gymproject.dto.CoachUpdateRequest;
import tw.gymproject.dto.CoachStatusRequest;

@RestController
@RequestMapping("/api/admin/coaches")
public class CoachManagementController {

    private final CoachManagementService coachManagementService;

    public CoachManagementController(CoachManagementService coachManagementService) {
        this.coachManagementService = coachManagementService;
    }

    @PostMapping
    public ResponseEntity<Coach> createCoach(
            @Valid @RequestBody CoachCreateRequest request) {

        Coach coach = coachManagementService.createCoach(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(coach);
    }

    @GetMapping
    public ResponseEntity<List<Coach>> getAllCoaches() {
        return ResponseEntity.ok(coachManagementService.getAllCoaches());
    }

    @PutMapping("/{coachid}")
    public ResponseEntity<Coach> updateCoach(
            @PathVariable("coachid") Integer coachid,
            @Valid @RequestBody CoachUpdateRequest request) {

        return ResponseEntity.ok(
                coachManagementService.updateCoach(coachid, request)
        );
    }

    @PatchMapping("/{coachid}/status")
    public ResponseEntity<Coach> updateCoachStatus(
            @PathVariable("coachid") Integer coachid,
            @Valid @RequestBody CoachStatusRequest request) {

        return ResponseEntity.ok(
                coachManagementService.updateCoachStatus(coachid, request)
        );
    }

    @GetMapping("/{coachid}")
    public ResponseEntity<Coach> getCoachById(
            @PathVariable("coachid") Integer coachid) {

        return ResponseEntity.ok(
                coachManagementService.getCoachById(coachid)
        );
    }
}