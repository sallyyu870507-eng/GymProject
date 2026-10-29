package tw.gymproject.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.CoachDashboardDTO;
import tw.gymproject.dto.CoachScheduleDTO;
import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.dto.ScheduleOptionDTO;
import tw.gymproject.service.BookingCoachService;


@RestController
@RequestMapping("/api/coach")
public class BookingCoachController {


    // =====================================================
    // Service
    // =====================================================

    private final BookingCoachService coachService;


    public BookingCoachController(
            BookingCoachService coachService) {

        this.coachService =
                coachService;
    }


    // =====================================================
    // 1. 教練查指定日期已預約課表
    //
    // GET
    // /api/coach/schedules?date=2026-10-31
    // =====================================================

    @GetMapping("/schedules")
    public List<CoachScheduleDTO> getBookedSchedule(

            @RequestParam LocalDate date,

            HttpSession session) {


        LoginResultDTO user =
                (LoginResultDTO)
                        session.getAttribute(
                                "user"
                        );


        if (user == null) {

            throw new RuntimeException(
                    "教練尚未登入"
            );
        }


        if (!"coach".equals(
                user.getRole()
        )) {

            throw new RuntimeException(
                    "沒有教練權限"
            );
        }


        Integer coachid =
                user.getCoachid();


        if (coachid == null) {

            throw new RuntimeException(
                    "找不到教練資料"
            );
        }


        return coachService
                .getBookedSchedules(
                        coachid,
                        date
                );
    }


    // =====================================================
    // 2. 教練 Dashboard
    //
    // GET
    // /api/coach/dashboard?date=2026-10-31
    // =====================================================

    @GetMapping("/dashboard")
    public CoachDashboardDTO getDashboard(

            @RequestParam LocalDate date,

            HttpSession session) {


        LoginResultDTO user =
                (LoginResultDTO)
                        session.getAttribute(
                                "user"
                        );


        if (user == null) {

            throw new RuntimeException(
                    "教練尚未登入"
            );
        }


        if (!"coach".equals(
                user.getRole()
        )) {

            throw new RuntimeException(
                    "沒有教練權限"
            );
        }


        Integer coachid =
                user.getCoachid();


        if (coachid == null) {

            throw new RuntimeException(
                    "找不到教練資料"
            );
        }


        return coachService
                .getDashboard(
                        coachid,
                        date
                );
    }


    // =====================================================
    // 3. 教練修改預約
    //    查可修改日期
    //
    // GET
    // /api/coach/bookings/{bookingid}/available-dates
    // =====================================================

    @GetMapping(
            "/bookings/{bookingid}/available-dates"
    )
    public List<LocalDate> getAvailableDatesForReschedule(

            @PathVariable Integer bookingid,

            HttpSession session) {


        LoginResultDTO user =
                (LoginResultDTO)
                        session.getAttribute(
                                "user"
                        );


        if (user == null) {

            throw new RuntimeException(
                    "教練尚未登入"
            );
        }


        if (!"coach".equals(
                user.getRole()
        )) {

            throw new RuntimeException(
                    "沒有教練權限"
            );
        }


        Integer coachid =
                user.getCoachid();


        if (coachid == null) {

            throw new RuntimeException(
                    "找不到教練資料"
            );
        }


        return coachService
                .getAvailableDatesForReschedule(
                        coachid,
                        bookingid
                );
    }


    // =====================================================
    // 4. 教練修改預約
    //    查指定日期可選時段
    //
    // GET
    // /api/coach/bookings/{bookingid}/schedules
    // ?date=2026-10-31
    // =====================================================

    @GetMapping(
            "/bookings/{bookingid}/schedules"
    )
    public List<ScheduleOptionDTO> getScheduleOptionsForReschedule(

            @PathVariable Integer bookingid,

            @RequestParam LocalDate date,

            HttpSession session) {


        LoginResultDTO user =
                (LoginResultDTO)
                        session.getAttribute(
                                "user"
                        );


        if (user == null) {

            throw new RuntimeException(
                    "教練尚未登入"
            );
        }


        if (!"coach".equals(
                user.getRole()
        )) {

            throw new RuntimeException(
                    "沒有教練權限"
            );
        }


        Integer coachid =
                user.getCoachid();


        if (coachid == null) {

            throw new RuntimeException(
                    "找不到教練資料"
            );
        }


        return coachService
                .getScheduleOptionsForReschedule(
                        coachid,
                        bookingid,
                        date
                );
    }


    // =====================================================
    // 5. 教練取消預約
    //
    // POST
    // /api/coach/bookings/{bookingid}/cancel
    //
    // 原本 PUT
    // 現在改成 POST
    // =====================================================

    @PostMapping(
            "/bookings/{bookingid}/cancel"
    )
    public ResponseEntity<?> cancelBookingByCoach(

            @PathVariable Integer bookingid,

            HttpSession session) {


        LoginResultDTO user =
                (LoginResultDTO)
                        session.getAttribute(
                                "user"
                        );


        if (user == null) {

            return ResponseEntity
                    .status(401)
                    .body(
                            "教練尚未登入"
                    );
        }


        if (!"coach".equals(
                user.getRole()
        )) {

            return ResponseEntity
                    .status(403)
                    .body(
                            "沒有教練權限"
                    );
        }


        Integer coachid =
                user.getCoachid();


        if (coachid == null) {

            return ResponseEntity
                    .status(401)
                    .body(
                            "找不到教練資料"
                    );
        }


        try {


            String result =
                    coachService
                            .cancelBookingByCoach(
                                    bookingid,
                                    coachid
                            );


            return ResponseEntity
                    .ok(result);


        } catch (RuntimeException e) {


            return ResponseEntity
                    .badRequest()
                    .body(
                            e.getMessage()
                    );
        }
    }


    // =====================================================
    // 6. 教練修改預約日期時間
    //
    // POST
    // /api/coach/bookings/{bookingid}/reschedule
    // ?newScheduleid=1234
    //
    // 不再使用 JSON Body
    // =====================================================

    @PostMapping(
            "/bookings/{bookingid}/reschedule"
    )
    public ResponseEntity<?> rescheduleBookingByCoach(

            @PathVariable Integer bookingid,

            @RequestParam Integer newScheduleid,

            HttpSession session) {


        LoginResultDTO user =
                (LoginResultDTO)
                        session.getAttribute(
                                "user"
                        );


        if (user == null) {

            return ResponseEntity
                    .status(401)
                    .body(
                            "教練尚未登入"
                    );
        }


        if (!"coach".equals(
                user.getRole()
        )) {

            return ResponseEntity
                    .status(403)
                    .body(
                            "沒有教練權限"
                    );
        }


        Integer coachid =
                user.getCoachid();


        if (coachid == null) {

            return ResponseEntity
                    .status(401)
                    .body(
                            "找不到登入教練資料"
                    );
        }


        if (newScheduleid == null) {

            return ResponseEntity
                    .badRequest()
                    .body(
                            "請選擇新的日期與時間"
                    );
        }


        try {


            String result =
                    coachService
                            .rescheduleBookingByCoach(
                                    bookingid,
                                    coachid,
                                    newScheduleid
                            );


            return ResponseEntity
                    .ok(result);


        } catch (RuntimeException e) {


            return ResponseEntity
                    .badRequest()
                    .body(
                            e.getMessage()
                    );
        }
    }
}