package tw.gymproject.controller;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.service.AccountService;
import org.springframework.beans.factory.annotation.Value;

@Controller
public class LoginController {
	
	@Value("${app.frontend-url}")
	private String frontendUrl;
    private final AccountService accountService;

    public LoginController(AccountService accountService) {
        this.accountService = accountService;
    }

    @GetMapping("/login")
    public String loginPage() {
        return "redirect:" + frontendUrl + "/login";
    }
//    @GetMapping("/login")
//    public String loginPage() {
//        return "forward:/login.html";
//    }

    @PostMapping("/login")
    public String login(
            @RequestParam(required = false) String username,
            @RequestParam(required = false) String password,
            HttpSession session) {
//    	boolean valid = accountService.verifyPassword("admin", "123456");
//    	System.out.println(valid);檢查密碼有無符合資料庫雜湊比對
    	
        if (username == null || username.isBlank()) {
            return "redirect:/login?error=usernameEmpty";
        }
        if (password == null || password.isBlank()) {
            return "redirect:/login?error=passwordEmpty";
        }

        LoginResultDTO result = accountService.login(username, password);
        if (!result.isSuccess()) {
            if ("INACTIVE".equals(result.getStatus())) {
                return "redirect:/login?error=inactive";
            }
            return "redirect:/login?error=invalid";
        }

        session.setAttribute("user", result);
        return switch (result.getRole()) {
            case "admin" -> "redirect:/admin";
            case "coach" -> "redirect:/coach";
            case "member" -> "redirect:/member";
            default -> "redirect:/login";
        };
    }

    @PostMapping("/logout")
    public String logout(HttpSession session) {
        if (session != null) {
            session.invalidate();
        }
        return "redirect:/login";
    }

    @GetMapping("/admin")
    public String adminPage() {
        return "redirect:" + frontendUrl + "/admin";
    }

    @GetMapping("/coach")
    public String coachPage() {
        return "redirect:" + frontendUrl + "/coach";
    }

    @GetMapping("/member")
    public String memberPage() {
        return "redirect:" + frontendUrl + "/member";
    }
//    @GetMapping("/admin")
//    public String adminPage() {
//        return "forward:/admin.html";
//    }
//
//    @GetMapping("/coach")
//    public String coachPage() {
//        return "forward:/coach.html";
//    }
//
//    @GetMapping("/member")
//    public String memberPage() {
//        return "forward:/member.html";
//    }
}
