package tw.gymproject.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class CoachMemberUpdateDTO {
	@NotBlank(message = "姓名不能為空")
	private String name;
	
	@Pattern(regexp = "^09\\d{8}$" , message = "手機號碼格式錯誤")
	@NotBlank(message = "手機不能為空")
	private String phone;
	
	private String email;
}
