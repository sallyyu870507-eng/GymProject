package tw.gym.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;

@RestController
@RequestMapping("/session-test")
public class SessionTestController {

    /*
     * 模擬會員登入
     */
    @GetMapping("/login-member")
    public String loginMember(HttpSession session) {

        session.setAttribute("role", "member");
        session.setAttribute("memberid", 1);

        return "模擬會員登入成功：role=member, memberid=1";
    }


    /*
     * 模擬教練登入
     */
    @GetMapping("/login-coach")
    public String loginCoach(HttpSession session) {

        session.setAttribute("role", "coach");
        session.setAttribute("coachid", 1);

        return "模擬教練登入成功：role=coach, coachid=1";
    }
    
    /*模擬管理員登入*/
    
    @GetMapping("/login-admin")
    public String loginAdmin(HttpSession session) {

        session.setAttribute("role", "admin");

        return "模擬管理員登入成功：role=admin";
    }
}