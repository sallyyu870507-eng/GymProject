package tw.gymproject.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
//修改會員可以變更的項目
public class MemberUpdateDTO {
	@NotBlank(message = "使用者名稱不能為空")
	@Pattern(
		    regexp = "^[A-Za-z0-9]{4,20}$",
		    message = "帳號必須為4~20位英文字母或數字"
		)
	private String username;
	
	@NotBlank(message = "姓名不能為空")
	private String name;
	
	@Pattern(regexp = "^09\\d{8}$" , message = "手機號碼格式錯誤")
	@NotBlank(message = "手機不能為空")
	private String phone;
	
	private String email;
	
//	@Past(message = "生日須早於今日")
//	@NotNull(message = "請填寫生日")
//	private LocalDate birthday;
	
	
	
	
}
