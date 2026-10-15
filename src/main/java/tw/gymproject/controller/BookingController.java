package tw.gymproject.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.BookingResponseDTO;
import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.dto.RescheduleDTO;
import tw.gymproject.entity.Booking;
import tw.gymproject.service.BookingService;

@RestController
@RequestMapping("/booking")
public class BookingController {

    // 會員端 controller-2
    private final BookingService bookingService;

    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }


    /*
     * STEP4
     * 會員新增預約
     */
    @PostMapping
    public ResponseEntity<?> createBooking(
            @RequestBody Booking booking,
            HttpSession session) {

        // 1. 從 Session 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO) session.getAttribute("user");

        // 2. 確認是否登入
        if (user == null) {
            return ResponseEntity
                    .status(401)
                    .body("會員尚未登入");
        }

        // 3. 確認是不是會員
        if (!"member".equals(user.getRole())) {
            return ResponseEntity
                    .status(403)
                    .body("沒有會員權限");
        }

        // 4. 取得登入會員 memberid
        Integer memberid = user.getMemberid();

        if (memberid == null) {
            return ResponseEntity
                    .status(401)
                    .body("找不到登入會員資料");
        }

        // 5. 建立預約
        try {

            BookingResponseDTO result =
                    bookingService.createBooking(
                            booking,
                            memberid
                    );

            return ResponseEntity.ok(result);

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(e.getMessage());
        }
    }


    /*
     * 會員查詢自己的預約
     */
    @GetMapping("/my")
    public ResponseEntity<?> getBookings(
            HttpSession session) {

        // 1. 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO) session.getAttribute("user");

        // 2. 沒有登入
        if (user == null) {
            return ResponseEntity
                    .status(401)
                    .body("會員尚未登入");
        }

        // 3. 權限判斷
        if (!"member".equals(user.getRole())) {
            return ResponseEntity
                    .status(403)
                    .body("沒有會員權限");
        }

        // 4. 取得登入會員 memberid
        Integer memberid = user.getMemberid();

        if (memberid == null) {
            return ResponseEntity
                    .status(401)
                    .body("找不到登入會員資料");
        }

        // 5. 查自己的預約
        List<BookingResponseDTO> bookings =
                bookingService.getMyBookings(memberid);

        return ResponseEntity.ok(bookings);
    }


    /*
     * 會員取消自己的預約
     */
    @PutMapping("/{bookingid}/cancel")
    public ResponseEntity<?> cancelBooking(
            @PathVariable Integer bookingid,
            HttpSession session) {

        // 1. 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO) session.getAttribute("user");

        // 2. 沒有登入
        if (user == null) {
            return ResponseEntity
                    .status(401)
                    .body("會員尚未登入");
        }

        // 3. 權限判斷
        if (!"member".equals(user.getRole())) {
            return ResponseEntity
                    .status(403)
                    .body("沒有會員權限");
        }

        // 4. 取得 memberid
        Integer memberid = user.getMemberid();

        if (memberid == null) {
            return ResponseEntity
                    .status(401)
                    .body("找不到登入會員資料");
        }

        // 5. 取消預約
        try {

            String result =
                    bookingService.cancelBooking(
                            bookingid,
                            memberid
                    );

            return ResponseEntity.ok(result);

        } catch (RuntimeException e) {

            return ResponseEntity
                    .badRequest()
                    .body(e.getMessage());
        }
    }
    
    /*會員修改日期時段*/
    @PutMapping("/{bookingid}/reschedule")
    public ResponseEntity<?> rescheduleBooking(
    		@PathVariable Integer bookingid,
    		@RequestBody RescheduleDTO request,
    		HttpSession session){
    	// 1. 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO) session.getAttribute("user");

        // 2. 沒有登入
        if (user == null) {
            return ResponseEntity
                    .status(401)
                    .body("會員尚未登入");
        }

        // 3. 權限判斷
        if (!"member".equals(user.getRole())) {
            return ResponseEntity
                    .status(403)
                    .body("沒有會員權限");
        }

        // 4. 取得 memberid
        Integer memberid = user.getMemberid();

        if (memberid == null) {
            return ResponseEntity
                    .status(401)
                    .body("找不到登入會員資料");
        }
        
        //5.確認傳新的scheduleid
        if (request.getNewScheduleid() == null) {
        	return ResponseEntity
        			.badRequest()
        			.body("請選擇新的日期與時間");
		}
        
        //6.修改預約
        try {
			String result =
					bookingService.rescheduleBooking(bookingid, memberid, request.getNewScheduleid());
			
			return ResponseEntity.ok(result);
		} catch (RuntimeException e) {
			return ResponseEntity
					.badRequest()
					.body(e.getMessage());
		}
 
    }
}