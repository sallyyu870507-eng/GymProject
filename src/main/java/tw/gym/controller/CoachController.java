package tw.gym.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;
import tw.gym.dto.CoachDashboardDTO;
import tw.gym.dto.CoachScheduleDTO;
import tw.gym.service.CoachService;

@RestController
@RequestMapping("/coaches")
public class CoachController {
	//教練端controller
	private final CoachService coachService;
	
	public CoachController(
			CoachService coachService) {
		this.coachService= coachService;
	}
	
	 /* 登入後教練查某一天已被預約的課表 */
	@GetMapping("/schedules")
	public List<CoachScheduleDTO> getBookedSchedule(
			@RequestParam LocalDate date,
			HttpSession session){
		
		//1.先取得角色
		String role=
				(String)session.getAttribute("role");
		
		//2.確認是不是教練
		if(!"coach".equals(role)) {
			throw new RuntimeException("沒有教練權限");
		}
		
		//3.從session取得coachid
		Integer coachid=
				(Integer)session.getAttribute("coachid");
		
		if(coachid == null) {
			throw new RuntimeException("找不到教練資料");
		}
		
		/*把資料交給coachservice*/
		return coachService.getBookedSchedules
				(coachid, date);
	}
	
	 /* 登入後教練查某一天的首頁統計 */
	@GetMapping("/dashboard")
	public CoachDashboardDTO getDashboard(
			@RequestParam LocalDate date,
			HttpSession session) {
		//1.先取得角色
				String role=
						(String)session.getAttribute("role");
				
				//2.確認是不是教練
				if(!"coach".equals(role)) {
					throw new RuntimeException("沒有教練權限");
				}
				
				//3.從session取得coachid
				Integer coachid=
						(Integer)session.getAttribute("coachid");
				
				if(coachid == null) {
					throw new RuntimeException("找不到教練資料");
				}
				
		
		return coachService.getDashboard(coachid, date);
	}
	
	/* 教練代取消課程 */
    @PutMapping("/{bookingid}/coach-cancel")
    public ResponseEntity<?> cancelBookingByCoach(
            @PathVariable Integer bookingid,
            HttpSession session) {

        // 1. 先取得角色
        String role =
                (String) session.getAttribute("role");

        // 2. 確認是不是教練
        if (!"coach".equals(role)) {

            return ResponseEntity
                    .status(403)
                    .body("沒有教練權限");
        }

        // 3. 從 Session 取得 coachid
        Integer coachid =
                (Integer) session.getAttribute("coachid");

        // 4. 如果沒有 coachid
        if (coachid == null) {

            return ResponseEntity
                    .status(401)
                    .body("教練尚未登入");
        }

        try {

            // 5. 呼叫 CoachService
            String result =
                    coachService.cancelBookingByCoach(
                            bookingid,
                            coachid
                    );

            // 6. 成功
            return ResponseEntity.ok(result);

        } catch (RuntimeException e) {

            // 7. 失敗
            return ResponseEntity
                    .badRequest()
                    .body(e.getMessage());
        }
    }
	
}
