package tw.gymproject.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CoachStatusRequest {

    @NotBlank(message = "請提供教練狀態")
    @Pattern(
            regexp = "^(active|inactive)$",
            message = "教練狀態只能是 active 或 inactive "
    )
    private String status;
}