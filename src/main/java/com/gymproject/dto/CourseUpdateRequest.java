package com.gymproject.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class CourseUpdateRequest {

    @NotBlank(message = "課程名稱不可空白")
    @Size(max = 100, message = "課程名稱最多 100 個字元")
    private String coursename;

    @NotBlank(message = "課程類型不可空白")
    @Size(max = 50, message = "課程類型最多 50 個字元")
    private String coursetype;

    @Size(max = 500, message = "課程說明最多 500 個字元")
    private String description;

    @NotNull(message = "請提供價格")
    @DecimalMin(value = "0.00", message = "價格不可小於 0")
    @Digits(integer = 8, fraction = 2,
            message = "價格最多 8 位整數、2 位小數")
    private BigDecimal price;
}