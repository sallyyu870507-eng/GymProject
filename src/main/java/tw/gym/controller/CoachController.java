package tw.gym.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
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
	
}
