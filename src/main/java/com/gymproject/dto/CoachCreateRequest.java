package com.gymproject.dto;

import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CoachCreateRequest {

    @NotNull(message = "帳號ID不可空白")
    @Positive(message = "帳號ID必須大於0")
    private Integer accountid;

    @NotBlank(message = "教練編號不可空白")
    @Size(max = 20, message = "教練編號最多20個字元")
    private String coachno;

    @NotBlank(message = "教練姓名不可空白")
    @Size(max = 50, message = "教練姓名最多50個字元")
    private String name;

    @Size(max = 10, message = "性別最多10個字元")
    private String gender;

    @Size(max = 20, message = "電話最多20個字元")
    private String phone;

    @Email(message = "Email格式不正確")
    @Size(max = 100, message = "Email最多100個字元")
    private String email;

    @Size(max = 200, message = "專長最多200個字元")
    private String specialty;
}