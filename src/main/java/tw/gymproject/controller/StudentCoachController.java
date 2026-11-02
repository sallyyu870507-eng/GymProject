package tw.gymproject.controller;

import tw.gymproject.dto.StudentCoachDetailResponse;
import tw.gymproject.dto.StudentCoachListResponse;
import tw.gymproject.service.StudentCoachService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/member/student/coaches")
public class StudentCoachController {

    private final StudentCoachService studentCoachService;

    public StudentCoachController(
            StudentCoachService studentCoachService) {
        this.studentCoachService = studentCoachService;
    }

    @GetMapping
    public ResponseEntity<List<StudentCoachListResponse>>
    getCoaches() {

        return ResponseEntity.ok(
                studentCoachService.getCoaches()
        );
    }

    @GetMapping("/{coachid}")
    public ResponseEntity<StudentCoachDetailResponse>
    getCoachById(
            @PathVariable("coachid") Integer coachid) {

        return ResponseEntity.ok(
                studentCoachService.getCoachById(coachid)
        );
    }
}