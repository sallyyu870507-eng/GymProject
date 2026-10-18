package tw.gymproject.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import tw.gymproject.dto.CoachMemberUpdateDTO;
import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.dto.MemberUpdateDTO;
import tw.gymproject.service.AccountService;
import tw.gymproject.service.CoachMemberService;

@RestController
@RequestMapping("/api/coach/members")
public class CoachMemberController {
//放教練頁面的學員管理功能
	
	private final  AccountService service;
	private final CoachMemberService coachService;

	CoachMemberController(AccountService service, CoachMemberService coachService) {
		this.service = service;
		this.coachService = coachService;
	}
	
	//教練只能看到有購買自己課程的學員
	@GetMapping
	// await fetch(`/api/admin/members?page=${page}&size=${size}`)
    public ResponseEntity<Map<String, Object>> getPageMembers(
    			@RequestParam(defaultValue = "0") int page, //預設第一頁
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "") String keyword,
            HttpSession session
    			) {
//		System.out.println("List controller");
//		System.out.println("status:" + status);
//		System.out.println("keyword:" + keyword);

		//用session去找id
	    LoginResultDTO user =
	            (LoginResultDTO) session.getAttribute("user");
	   
	    Integer coachid = user.getCoachid();

	        return ResponseEntity.ok(
	        		coachService.findCoachMembers(page, size, coachid, keyword)
	        );
		
	
    }


	//修改會員，先查，後改
	@GetMapping("/{memberid}")
	public ResponseEntity<CoachMemberUpdateDTO> getMember(
            @PathVariable Integer memberid,
            HttpSession session            
            ) {

		LoginResultDTO user =
	            (LoginResultDTO) session.getAttribute("user");
	   
	    Integer coachid = user.getCoachid();
		
	    CoachMemberUpdateDTO dto =
        		coachService.getMemberForEdit(memberid, coachid);
        //例外已經在Service設定拋出給全域例外處理了
        return ResponseEntity.ok(dto);
    }

	//將更改的會員資料給Service存進資料庫
	@PutMapping("/update/{memberid}")
	public ResponseEntity<Map<String, Object>> updateMember(
            @PathVariable Integer memberid,
            @Valid @RequestBody CoachMemberUpdateDTO dto, //用JSON格式的Requestbody來接POST資料較隱私
            HttpSession session
            ) {
		System.out.println("進入PUT controller，MemberUpdateDTO:" + dto);
		LoginResultDTO user =
	            (LoginResultDTO) session.getAttribute("user");
	   
	    Integer coachid = user.getCoachid();
	    
		coachService.updateCoachMember(memberid, coachid, dto);

        return ResponseEntity.ok(
            Map.of(
                "success", true, //讓前端response.success的boolean做if判斷
                "message", "會員資料更新成功"
            )
        );
	}
	
}
