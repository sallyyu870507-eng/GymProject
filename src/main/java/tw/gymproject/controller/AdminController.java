package tw.gymproject.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import tw.gymproject.dto.RegisterDTO;
import tw.gymproject.service.AccountService;
import tw.gymproject.service.CoachService;

@RestController  //同時包含requestbody回傳JSON格式和controller
@RequestMapping("/api/admin/members")
public class AdminController {
//放管理員頁面的會員管理功能
		
	//引入寫業務邏輯的Service
	private final  AccountService service;
	private final CoachService coachService;

	AdminController(AccountService service, CoachService coachService) {
		this.service = service;
		this.coachService = coachService;
	}
	//新增會員(註冊)
	@PostMapping
	public ResponseEntity<Map<String, Object>> createMember(@RequestBody @Valid RegisterDTO dto,
															BindingResult bindingResult){

		System.out.println("---進入新增會員controller---");
	    Map<String, Object> result = new HashMap<>();
	    
	    try { //Service端可能會拋出例外
			System.out.println("---進入新增會員Service---");

	    	service.registerMember(dto);  //因為Service中設定的回傳是true或例外，如果沒有回傳false可以不用特別給變數
	    	result.put("success", true);
	    	result.put("message", "新增會員成功");
	        return ResponseEntity.ok(result);  //回傳HTTP狀態碼
//	        return "redirect:/admin/members"
	        
	    }catch (Exception e) {
	    	e.printStackTrace();//測試追蹤除錯用
	    	result.put("success", false);
	    	result.put("message", e.getMessage()); //這邊放service設定的拋出例外訊息
		    return ResponseEntity.badRequest().body(result); //400

		}
	}
	
	//顯示會員頁清單
	@GetMapping
	// await fetch(`/api/admin/members?page=${page}&size=${size}`)
    public ResponseEntity<Map<String, Object>> getPageMembers(
    		@RequestParam(defaultValue = "0") int page, //預設第一頁
            @RequestParam(defaultValue = "10") int size) {
		System.out.println("List controller");
		return ResponseEntity.ok(
		        service.findAllMembers(page, size)
		    );
    }

	
//	//查詢會員(依據狀態,狀態選項可使用projection)
//	@GetMapping
//	public ResponseEntity<Map<String, Object>> findAll() 
//	
	
	
	//修改會員
//	@PutMapping
//	public void updateMember()
	
	
	//刪除(inactive)會員
	@DeleteMapping("/del/{accountid}")
	public ResponseEntity<?> deleteMember(@PathVariable Integer accountid){
		
		service.softDeleteAccount(accountid);
		
		return ResponseEntity.ok("帳號停用成功");
		
/*		如果沒有使用全域例外處理器，要記得try-catch
 		try {
			service.softDeleteAccount(accountid);
			return ResponseEntity.ok("帳號停用成功");
			
		} catch (EntityNotFoundException e) {
	        // 當找不到帳號時，回傳 404 Not Found 與錯誤訊息
	        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("停用失敗：找不到該會員帳號");
	    } catch (Exception e) {
	        // 捕捉其他未知錯誤（如資料庫異常），回傳 500 Internal Server Error
	        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("系統發生錯誤，請稍後再試");
	    }
*/		
	}
	
}
	






/*	------------------------------------------------------------------------------------------------------------

	//新增教練+帳號
	@PostMapping("/coach")
	public ResponseEntity<Map<String, Object>> createCoach(@RequestBody @Validated CoachRegisterDTO coachDTO){  //如果要接多筆資料要使用List<DTO>

		boolean success = coachService.registerCoach(coachDTO);  //因為Service中設定的回傳是boolean
	    Map<String, Object> result = new HashMap<>();

	    result.put("success", success);

	    if (success) {
	        result.put("message", "新增教練成功");
	        return ResponseEntity.ok(result);  //回傳HTTP狀態碼
//	        return "redirect:/admin/members"
	    }
	    result.put("message", "帳號已存在");
	    return ResponseEntity.badRequest().body(result);
	}
	

新增管理員用=>單純建立帳密=>直接使用entity

@Autowired
private AccountRepository repository ;
	
@PostMapping("/boss/admin")
public void addAdmin(@RequestBody Useraccount admin) { 

admin.setUsername(admin.getUsername());
admin.setPassword(BCrypt.hashpw(admin.getPassword(), BCrypt.gensalt()));
admin.setRole("admin");
admin.setSatus("active");

Useraccount savedAdmin = repository.save(admin);
System.out.println(savedAdmin);

}
*/
