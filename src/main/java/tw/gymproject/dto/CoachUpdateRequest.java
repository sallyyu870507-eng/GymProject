package tw.gymproject.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CoachUpdateRequest {

    @NotBlank(message = "教練編號不可空白")
    @Size(max = 20, message = "教練編號最多 20 個字元")
    private String coachno;

    @NotBlank(message = "姓名不可空白")
    @Size(max = 50, message = "姓名最多 50 個字元")
    private String name;

    @Size(max = 10)
    private String gender;

    @Size(max = 20)
    private String phone;

    @Email(message = "Email 格式不正確")
    @Size(max = 100)
    private String email;

    @Size(max = 200)
    private String specialty;
}