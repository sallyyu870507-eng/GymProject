package tw.gymproject.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CoachRegisterDTO {
	@NotBlank(message = "使用者名稱不能為空")
	@Size(min = 4, max = 50)
	private String username;
	@NotBlank(message = "姓名不能為空")
	private String name;
	@NotBlank(message = "密碼不能為空")
	@Size(min = 4, max = 50)
	private String password;
	
	private String gender;
	@Pattern(regexp = "^09\\d{8}$")
	private String phone;
	@Email
	private String email;
	
	private String specialty;
	
	
}
