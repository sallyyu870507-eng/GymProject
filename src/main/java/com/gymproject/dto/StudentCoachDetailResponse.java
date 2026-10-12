package com.gymproject.dto;

import com.gymproject.entity.Coach;
import lombok.Getter;

@Getter
public class StudentCoachDetailResponse {

    private final Integer coachid;
    private final String name;
    private final String gender;
    private final String phone;
    private final String email;
    private final String specialty;

    public StudentCoachDetailResponse(Coach coach) {
        this.coachid = coach.getCoachid();
        this.name = coach.getName();
        this.gender = coach.getGender();
        this.phone = coach.getPhone();
        this.email = coach.getEmail();
        this.specialty = coach.getSpecialty();
    }
}