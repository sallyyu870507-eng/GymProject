package com.gymproject.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CourseStatusRequest {

    @NotBlank(message = "請提供課程狀態")
    @Pattern(
            regexp = "^(active|inactive)$",
            message = "課程狀態只能是 active 或 inactive "
    )
    private String status;
}