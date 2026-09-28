package tw.gymproject.controller;

import java.security.PublicKey;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import tw.gymproject.dto.RegisterDTO;
import tw.gymproject.service.AccountService;

@RestController  //同時包含requestbody回傳JSON格式和controller
@RequestMapping("/admin/members")
public class AdminController {
//放管理員頁面的會員管理功能
	//引入寫業務邏輯的Service
	private final  AccountService service;

	AdminController(AccountService service) {
		this.service = service;
	}

	//新增會員
	@PostMapping
	public ResponseEntity<Map<String, Object>> createMember(@RequestBody @Validated RegisterDTO dto){

		boolean success = service.registerMember(dto);  //因為Service中設定的回傳是boolean
	    Map<String, Object> result = new HashMap<>();

	    result.put("success", success);

	    if (success) {
	        result.put("message", "新增會員成功");
	        return ResponseEntity.ok(result);  //回傳HTTP狀態碼
	    }
	    result.put("message", "帳號已存在");
	    return ResponseEntity.badRequest().body(result);
		
	}
	
//	//查詢會員
//	@GetMapping
//	public void findBy 
//	
	
	
	//修改會員
//	@PutMapping
//	public void updateMember()
	
	
	//刪除(inactive)會員
	
	
	
//測試用
//	@GetMapping
//    public void findAll(){
//        System.out.println("findAll()"); }

}
