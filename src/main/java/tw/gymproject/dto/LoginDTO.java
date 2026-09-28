package tw.gymproject.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class LoginDTO {
	@NotBlank(message = "請填入使用者名稱")
	private String username;
	@NotBlank(message = "密碼不可為空")
	@Size(min = 4, max = 50)
	private String password;

}
