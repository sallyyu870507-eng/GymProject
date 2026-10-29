package tw.gymproject.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.BookingMemberCourseDTO;
import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.dto.ScheduleOptionDTO;
import tw.gymproject.service.ReservationOptionService;


@RestController
@RequestMapping("/api/member")
public class ReservationOptionController {

    // =====================================================
    // 會員端 Controller
    // =====================================================

    private final ReservationOptionService reservationOptionService;


    public ReservationOptionController(
            ReservationOptionService reservationOptionService) {

        this.reservationOptionService =
                reservationOptionService;
    }


    // =====================================================
    // STEP 1
    // 查會員已購買且還有剩餘堂數的課程
    // 同時帶出課程對應教練
    //
    // GET
    // /api/member/courses
    // =====================================================

    @GetMapping("/courses")
    public List<BookingMemberCourseDTO> getPurchasedCourses(
            HttpSession session) {


        // 1. 從 Session 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO)
                session.getAttribute(
                        "user"
                );


        // 2. 確認是否登入
        if (user == null) {

            throw new RuntimeException(
                    "尚未登入"
            );
        }


        // 3. 確認是不是會員
        if (!"member".equals(
                user.getRole()
        )) {

            throw new RuntimeException(
                    "沒有會員權限"
            );
        }


        // 4. 取得會員 id
        Integer memberid =
                user.getMemberid();


        // 5. 確認 memberid 存在
        if (memberid == null) {

            throw new RuntimeException(
                    "找不到登入會員資料"
            );
        }


        // 6. 查會員自己的已購課程
        return reservationOptionService
                .getPurchasedCourses(
                        memberid
                );
    }


    // =====================================================
    // STEP 2
    // 依會員課程查可預約日期
    //
    // GET
    // /api/member/courses/{membercourseid}/available-dates
    // =====================================================

    @GetMapping(
            "/courses/{membercourseid}/available-dates"
    )
    public List<LocalDate> getAvailableDates(
            @PathVariable Integer membercourseid,
            HttpSession session) {


        // 1. 從 Session 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO)
                session.getAttribute(
                        "user"
                );


        // 2. 確認是否登入
        if (user == null) {

            throw new RuntimeException(
                    "尚未登入"
            );
        }


        // 3. 確認是不是會員
        if (!"member".equals(
                user.getRole()
        )) {

            throw new RuntimeException(
                    "沒有會員權限"
            );
        }


        // 4. 取得會員 id
        Integer memberid =
                user.getMemberid();


        // 5. 確認 memberid 存在
        if (memberid == null) {

            throw new RuntimeException(
                    "找不到登入會員資料"
            );
        }


        // 6. 查可預約日期
        return reservationOptionService
                .getAvailableDatesByMemberCourse(
                        memberid,
                        membercourseid
                );
    }


    // =====================================================
    // STEP 3
    // 依日期找出所有時段
    //
    // GET
    // /api/member/courses/{membercourseid}/schedules
    // ?date=2026-10-30
    // =====================================================

    @GetMapping(
            "/courses/{membercourseid}/schedules"
    )
    public List<ScheduleOptionDTO> getScheduleOptions(
            @PathVariable Integer membercourseid,
            @RequestParam LocalDate date,
            HttpSession session) {


        // 1. 從 Session 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO)
                session.getAttribute(
                        "user"
                );


        // 2. 確認是否登入
        if (user == null) {

            throw new RuntimeException(
                    "尚未登入"
            );
        }


        // 3. 確認是不是會員
        if (!"member".equals(
                user.getRole()
        )) {

            throw new RuntimeException(
                    "沒有會員權限"
            );
        }


        // 4. 取得會員 id
        Integer memberid =
                user.getMemberid();


        // 5. 確認 memberid 存在
        if (memberid == null) {

            throw new RuntimeException(
                    "找不到登入會員資料"
            );
        }


        // 6. 查指定日期時段
        return reservationOptionService
                .getScheduleOptionsByMemberCourse(
                        memberid,
                        membercourseid,
                        date
                );
    }
}