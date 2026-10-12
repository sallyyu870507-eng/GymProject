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
            regexp = "^(上架|下架)$",
            message = "課程狀態只能是「上架」或「下架」"
    )
    private String status;
}