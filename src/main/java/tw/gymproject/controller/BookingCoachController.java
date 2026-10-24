package tw.gymproject.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.CoachDashboardDTO;
import tw.gymproject.dto.CoachScheduleDTO;
import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.dto.RescheduleDTO;
import tw.gymproject.service.BookingCoachService;
@RestController
@RequestMapping("/coaches")
public class BookingCoachController {

    // 教練端 controller
    private final BookingCoachService coachService;

    public BookingCoachController(
            BookingCoachService coachService) {

        this.coachService = coachService;
    }


    /*
     * 登入後教練查某一天
     * 已被預約的課表
     */
    @GetMapping("/schedules")
    public List<CoachScheduleDTO> getBookedSchedule(
            @RequestParam LocalDate date,
            HttpSession session) {

        // 1. 從 Session 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO) session.getAttribute("user");

        // 2. 確認是否登入
        if (user == null) {
            throw new RuntimeException("教練尚未登入");
        }

        // 3. 確認是不是教練
        if (!"coach".equals(user.getRole())) {
            throw new RuntimeException("沒有教練權限");
        }

     // 4. 從登入資料取得 coachid
        Integer coachid =
                user.getCoachid();

        System.out.println("目前登入 coachid = " + coachid);

        // 5. 確認 coachid 存在
        if (coachid == null) {
            throw new RuntimeException("找不到教練資料");
        }

        // 6. 交給 Service 查課表
        return coachService
                .getBookedSchedules(
                        coachid,
                        date
                );
    }


    /*
     * 登入後教練查某一天
     * 首頁統計
     */
    @GetMapping("/dashboard")
    public CoachDashboardDTO getDashboard(
            @RequestParam LocalDate date,
            HttpSession session) {

        // 1. 從 Session 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO) session.getAttribute("user");

        // 2. 確認是否登入
        if (user == null) {
            throw new RuntimeException("教練尚未登入");
        }

        // 3. 確認是不是教練
        if (!"coach".equals(user.getRole())) {
            throw new RuntimeException("沒有教練權限");
        }

        // 4. 取得 coachid
        Integer coachid =
                user.getCoachid();

        // 5. 確認 coachid 存在
        if (coachid == null) {
            throw new RuntimeException("找不到教練資料");
        }

        // 6. 查首頁統計
        return coachService
                .getDashboard(
                        coachid,
                        date
                );
    }


    /*
     * 教練代取消課程
     */
    @PutMapping("/{bookingid}/coach-cancel")
    public ResponseEntity<?> cancelBookingByCoach(
            @PathVariable Integer bookingid,
            HttpSession session) {

        // 1. 從 Session 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO) session.getAttribute("user");

        // 2. 確認是否登入
        if (user == null) {

            return ResponseEntity
                    .status(401)
                    .body("教練尚未登入");
        }

        // 3. 確認是不是教練
        if (!"coach".equals(user.getRole())) {

            return ResponseEntity
                    .status(403)
                    .body("沒有教練權限");
        }

        // 4. 取得 coachid
        Integer coachid =
                user.getCoachid();

        // 5. 確認 coachid 存在
        if (coachid == null) {

            return ResponseEntity
                    .status(401)
                    .body("找不到教練資料");
        }

        try {

            // 6. 呼叫 Service
            String result =
                    coachService.cancelBookingByCoach(
                            bookingid,
                            coachid
                    );

            return ResponseEntity.ok(result);

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(e.getMessage());
        }
    }
    /* 教練修改日期與時間 */
    @PutMapping("/{bookingid}/reschedule")
    public ResponseEntity<?> rescheduleBookingByCoach(
            @PathVariable Integer bookingid,
            @RequestBody RescheduleDTO request,
            HttpSession session) {

        // 1. 取得登入者
        LoginResultDTO user =
                (LoginResultDTO)
                        session.getAttribute("user");


        // 2. 沒登入
        if (user == null) {

            return ResponseEntity
                    .status(401)
                    .body("教練尚未登入");
        }


        // 3. 權限
        if (!"coach".equals(
                user.getRole()
        )) {

            return ResponseEntity
                    .status(403)
                    .body("沒有教練權限");
        }


        // 4. coachid
        Integer coachid =
                user.getCoachid();


        if (coachid == null) {

            return ResponseEntity
                    .status(401)
                    .body("找不到登入教練資料");
        }


        // 5. 一定要傳 newScheduleid
        if (request.getNewScheduleid() == null) {

            return ResponseEntity
                    .badRequest()
                    .body(
                            "請選擇新的日期與時間"
                    );
        }


        try {

            // 6. 修改
            String result =
                    coachService
                            .rescheduleBookingByCoach(
                                    bookingid,
                                    coachid,
                                    request.getNewScheduleid()
                            );


            return ResponseEntity.ok(
                    result
            );


        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(
                            e.getMessage()
                    );
        }
    }
}