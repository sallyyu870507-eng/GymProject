package tw.gymproject.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import tw.gymproject.dto.AdminPurchaseReqDTO;
import tw.gymproject.dto.PurchaseCoachDTO;
import tw.gymproject.dto.PurchaseCourseDTO;
import tw.gymproject.service.AdminPurchaseCourse;

@RestController
@RequestMapping("/api/admin/purchases")
public class AdminPurchaseCourseController {
	
	private final AdminPurchaseCourse adminPurchaseCourse;
	AdminPurchaseCourseController(AdminPurchaseCourse adminPurchaseCourse){
		this.adminPurchaseCourse=adminPurchaseCourse;
	}
	
	@GetMapping("/courses")
 	//只需要顯示清單，不用調整Http狀態碼所以回List
	public List<PurchaseCourseDTO> getPurchaseCourses() {

	    return adminPurchaseCourse.getAvailableCourses();
	}
	
	
	@GetMapping("/courses/{courseId}/coaches")
	public List<PurchaseCoachDTO> getPurchaseCoaches(
	        @PathVariable Integer courseId) {

	    return adminPurchaseCourse.getAvailableCoaches(courseId);
	}


	
	@PostMapping("/{memberId}/purchases")
	public ResponseEntity<Map<String, Object>> createPurchase(
	        @PathVariable Integer memberId,
	        @Valid @RequestBody AdminPurchaseReqDTO dto) {

	    Integer purchaseId =
	    		adminPurchaseCourse.createPurchase(memberId, dto);

	    return ResponseEntity
	            .status(HttpStatus.CREATED)
	            .body(Map.of(
	                "success", true,
	                "message", "購課成功",
	                "membercourseid", purchaseId
	            ));
	}
}
