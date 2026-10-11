package tw.gymproject.dto;

import lombok.Data;

@Data
public class LoginResultDTO { //接登入後 需要抓的資料
	private Integer accountid;
	private String username;
	private String name;
    private String role;
    private String memberno;
    private String coachno;
    
    //讓Service回傳給controller辨別用
    private boolean success;
    private String status;
}
