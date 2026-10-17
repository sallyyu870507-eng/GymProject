package tw.gymproject.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterDTO {
//用來接註冊前端傳進來的資料，接著分別存到account和member的entity，
	@NotBlank(message = "使用者名稱不能為空")
	@Pattern(
		    regexp = "^[A-Za-z0-9]{4,20}$",
		    message = "帳號必須為4~20位英文字母或數字"
		)
	private String username;
	
	@NotBlank(message = "密碼不能為空")
	@Size(min = 4, max = 50 , message = "密碼至少為四字元")
	private String password;

	@NotBlank(message = "姓名不能為空")
	private String name;
	private String gender;
	
	@Pattern(regexp = "^09\\d{8}$" , message = "手機號碼格式錯誤")
	@NotBlank(message = "手機不能為空")
	private String phone;
	
	@Email
	private String email;
	
	@Past(message = "生日須早於今日")
	@NotNull(message = "請填寫生日")
	private LocalDate birthday;
	

	
}
