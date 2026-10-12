package com.gymproject.dto;

import com.gymproject.entity.Coach;
import lombok.Getter;

@Getter
public class StudentCoachListResponse {

    private final Integer coachid;
    private final String name;

    public StudentCoachListResponse(Coach coach) {
        this.coachid = coach.getCoachid();
        this.name = coach.getName();
    }
}