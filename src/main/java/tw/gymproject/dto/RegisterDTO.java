package tw.gymproject.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterDTO {
//用來接註冊前端傳進來的資料，接著分別存到account和member的entity，
	@NotNull(message = "使用者名稱不能為空")
	@Size(min = 4, max = 50)
	private String username;
	
	@NotNull(message = "密碼不能為空")
	@Size(min = 4, max = 50)
	private String password;
	
	private String memberno;
	@NotNull(message = "姓名不能為空")
	private String name;
	private String gender;
	@Pattern(regexp = "^09\\d{8}$")
	private String phone;
	@Email
	private String email;
	
	@Past
	private LocalDate birthday;
	
}
