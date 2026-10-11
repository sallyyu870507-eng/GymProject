package tw.gymproject.dto;

import java.time.LocalDate;

import lombok.Data;

@Data
//修改會員可以變更的項目
public class MemberUpdateDTO {
	private String name;//
	private String gender;
	private String phone;//
	private String email;
	private LocalDate birthday;
}
