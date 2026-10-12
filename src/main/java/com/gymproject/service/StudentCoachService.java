package com.gymproject.service;

import com.gymproject.dto.StudentCoachDetailResponse;
import com.gymproject.dto.StudentCoachListResponse;
import com.gymproject.entity.Coach;
import com.gymproject.repository.CoachRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class StudentCoachService {

    private final CoachRepository coachRepository;

    public StudentCoachService(CoachRepository coachRepository) {
        this.coachRepository = coachRepository;
    }

    @Transactional(readOnly = true)
    public List<StudentCoachListResponse> getCoaches() {

        return coachRepository
                .findByStatusOrderByCoachidAsc("在職")
                .stream()
                .map(StudentCoachListResponse::new)
                .toList();
    }

    @Transactional(readOnly = true)
    public StudentCoachDetailResponse getCoachById(
            Integer coachid) {

        Coach coach = coachRepository
                .findByCoachidAndStatus(coachid, "在職")
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "此教練已停用或不存在"));

        return new StudentCoachDetailResponse(coach);
    }
}