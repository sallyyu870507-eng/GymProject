package tw.gymproject.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.LoginResultDTO;


@RestController //確保所有response都是JSON格式
@RequestMapping("/api/user")
public class ApiUserController {
//歡迎登入者 名字
    //傳給前端登入者的資訊讓抓去前端顯示


    @GetMapping
    public ResponseEntity<Map<String, Object>> getCurrentUser(HttpSession session) {
        Map<String, Object> response = new HashMap<>();
        //取出登入時塞入session的user
        LoginResultDTO user =
                (LoginResultDTO) session.getAttribute("user");

        if (user == null) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(response);
        }

        //發給前端的內容
        response.put("username", user.getUsername());
        response.put("name", user.getName());
        response.put("role", user.getRole());
        //使用Map可以多加想要給前端的key-value資訊
        return ResponseEntity.ok(response);
    }
}