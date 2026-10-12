package com.gymproject.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CoachStatusRequest {

    @NotBlank(message = "請提供教練狀態")
    @Pattern(
            regexp = "^(在職|停用)$",
            message = "教練狀態只能是「在職」或「停用」"
    )
    private String status;
}