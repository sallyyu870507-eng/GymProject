package tw.gym.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;
import tw.gym.dto.MemberCourseDTO;
import tw.gym.dto.ScheduleOptionDTO;
import tw.gym.service.ReservationOptionService;

@RestController
@RequestMapping
public class ReservationOptionController {
	
	//會員端controller-1
    private final ReservationOptionService reservationOptionService;

    public ReservationOptionController(
            ReservationOptionService reservationOptionService) {

        this.reservationOptionService = reservationOptionService;
    }

    /* STEP1查會員已購買且還有剩餘堂數的課程
     * 還有課程相對應的教練 */
    @GetMapping("/members/courses")
    public List<MemberCourseDTO> getPurchasedCourses(
            HttpSession session) {

        // 1. 從 Session 取得角色
        String role =
                (String) session.getAttribute("role");


        // 2. 確認目前登入者是不是會員
        if (!"member".equals(role)) {
            throw new RuntimeException("沒有會員權限");
        }


        // 3. 從 Session 取得 memberid
        Integer memberid =
                (Integer) session.getAttribute("memberid");


        // 4. 如果 Session 沒有 memberid
        if (memberid == null) {
            throw new RuntimeException("找不到登入會員資料");
        }


        // 5. 查這位會員自己的已購課程
        return reservationOptionService
                .getPurchasedCourses(memberid);
    }

    
    
    
    
    /*STEP2依課程教練查可預約日期*/
    @GetMapping("/members/courses/{membercourseid}/available-dates")
    public List<LocalDate> getAvailableDates(
            @PathVariable Integer membercourseid,
            HttpSession session) {

        // 1. 取得角色
        String role =
                (String) session.getAttribute("role");


        // 2. 權限判斷
        if (!"member".equals(role)) {
            throw new RuntimeException("沒有會員權限");
        }


        // 3. 取得 memberid
        Integer memberid =
                (Integer) session.getAttribute("memberid");


        // 4. 確認 Session 有 memberid
        if (memberid == null) {
            throw new RuntimeException("找不到登入會員資料");
        }


        // 5. 查可預約日期
        return reservationOptionService
                .getAvailableDatesByMemberCourse(
                        memberid,
                        membercourseid
                );
    }

    
    /*STEP3 依日期找出所有時段*/
    @GetMapping("/members/courses/{membercourseid}/schedules")
    public List<ScheduleOptionDTO> getScheduleOptions(
            @PathVariable Integer membercourseid,
            @RequestParam LocalDate date,
            HttpSession session) {

        // 1. 取得角色
        String role =
                (String) session.getAttribute("role");


        // 2. 權限判斷
        if (!"member".equals(role)) {
            throw new RuntimeException("沒有會員權限");
        }


        // 3. 取得登入會員 memberid
        Integer memberid =
                (Integer) session.getAttribute("memberid");


        // 4. 確認 memberid 存在
        if (memberid == null) {
            throw new RuntimeException("找不到登入會員資料");
        }


        // 5. 查時段
        return reservationOptionService
                .getScheduleOptionsByMemberCourse(
                        memberid,
                        membercourseid,
                        date
                );
    }
}