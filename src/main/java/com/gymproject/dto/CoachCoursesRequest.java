package com.gymproject.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class CoachCoursesRequest {

    @NotNull(message = "請提供課程 ID 清單")
    private List<
            @NotNull(message = "課程 ID 不可為 null")
            @Positive(message = "課程 ID 必須大於 0")
                    Integer> courseids;
}