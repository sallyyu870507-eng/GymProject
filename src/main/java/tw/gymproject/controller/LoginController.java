package tw.gymproject.controller;

import java.security.PrivateKey;
import java.util.HashMap;
import java.util.Map;

import org.aspectj.apache.bcel.classfile.Module.Require;
import org.mindrot.jbcrypt.BCrypt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.relational.core.sql.FalseCondition;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import jakarta.persistence.criteria.CriteriaBuilder.Case;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import tw.gymproject.dto.CoachRegisterDTO;
import tw.gymproject.dto.LoginDTO;
import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.dto.RegisterDTO;
import tw.gymproject.entity.Coach;
import tw.gymproject.entity.Member;
import tw.gymproject.entity.Useraccount;
import tw.gymproject.repository.AccountRepository;
import tw.gymproject.repository.CoachRepository;
import tw.gymproject.repository.MemberRepository;
import tw.gymproject.service.AccountService;

@Controller   //傳字串而非JSON
public class LoginController {
	
	private AccountService accountService;
	
	public LoginController(AccountService accountService) {
        this.accountService = accountService;
    }
	
	@GetMapping("/login")
	  public String loginPage() {
        return "forward:/login.html";
    }
	
	//純登入驗證身分用，驗證後分別指派到三個頁面
	@PostMapping("/login")
	public String login(@RequestParam(required = false) String username,
						@RequestParam(required = false) String password,
            			HttpSession session) {
//		@RequestBody @Valid LoginDTO loginDTO用在前端傳入的是JSON檔時
	
		//後端第二道使用者輸入與否檢查防線
		if(username == null || username.isBlank()) {
			return "redirect:/login.html?error=usernameEmpty";
		}
		if(password == null || password.isBlank()) {
			return "redirect:/login.html?error=passwordEmpty";
		}
			
		LoginResultDTO result = accountService.login(username, password);
		//等Service那邊傳回來的東西
		
		
		//檢查帳號狀態
		if(!result.isSuccess()) {
			
			//這是Service回傳的字串不是資料庫的
			if("INACTIVE".equals(result.getStatus())) {
				return "redirect:/login?error=inactive";
		}
			return "redirect:/login?error=invalid";//登入失敗:帳號無效或密碼錯誤

		}
		 session.setAttribute("user", result);

	        switch (result.getRole()) {

	            case "admin":
	                return "redirect:/admin";//呼叫GET API forward進入管理員頁面

	            case "coach":
	                return "redirect:/coach";//進入教練學員頁面

	            case "member":
	                return "redirect:/member";//進入學員頁面

	            default:
	                return "redirect:/login";
       }
	}
	
	@PostMapping("/logout")
	String logout(HttpSession session){
		if(session != null) {
        session.invalidate();
        }
        return "redirect:/login"; //由瀏覽器重新發送請求到靜態頁面
	}
	
	@GetMapping("/admin")
	public String adminPage() {
		return "forward:/admin.html"; //還沒套用React時使用
	    //return "forward:/member-management.html"; //由伺服器內部轉發換畫面
	}

	@GetMapping("/coach")
	public String coachPage() {
	    return "forward:/coach.html";
	    //return "forward:/member-management.html";
	}

	@GetMapping("/member")
	public String memberPage() {
		return "forward:/member.html";
	}
	
	
}








