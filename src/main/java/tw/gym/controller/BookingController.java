package tw.gym.controller;

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
import tw.gym.dto.BookingResponseDTO;
import tw.gym.entity.Booking;
import tw.gym.service.BookingService;

@RestController
@RequestMapping("/booking")
public class BookingController {
	//會員端controller-2
	private final BookingService bookingService;
	
	public BookingController(BookingService bookingService) {
		this.bookingService =bookingService;
	}
	
	@PostMapping
	/*ResponseEntity<?>：這個方法回傳的是一個 HTTP 回應。*/
	public ResponseEntity<?> createBooking(@RequestBody Booking booking) {
		try {
			BookingResponseDTO result = bookingService.createBooking(booking);
			return ResponseEntity.ok(result);
		}catch (RuntimeException e) {
			return ResponseEntity
					.badRequest()
					.body(e.getMessage());
		}
	}
	
	/*會員查詢自己的預約*/
	@GetMapping("/my")
	public ResponseEntity<?> getBookings(HttpSession session){
		
		// ① 從 Session 找會員 ID
		Integer memberid =
				(Integer)session.getAttribute("memberid");
		 // ② 如果沒有登入
		if(memberid == null) {
			return ResponseEntity
					.status(401)
					.body("會員尚未登入");
		}
		 // ③ 呼叫 Service 查詢
		 List<BookingResponseDTO> bookings =
				 bookingService.getMyBookings(memberid);
		 
		 // ④ 回傳 JSON
		 return ResponseEntity.ok(bookings);
	}
	
	/*會員取消自己的預約*/
	@PutMapping("/{bookingid}/cancel")
	public ResponseEntity<?> cancelBooking(
			@PathVariable Integer bookingid,
			HttpSession session){
		//1.從session拿memberid
		Integer memberid =
				(Integer) session.getAttribute("memberid");
		
		//2.沒有登入
		if(memberid == null) {
			return ResponseEntity
					.status(401)
					.body("會員尚未登入");
		}
		
		try {
			//3.呼叫service
			String result =
					bookingService.cancelBooking(bookingid, memberid);
			
			//4.成功
			return ResponseEntity.ok(result);
			
			
		} catch (RuntimeException e) {
			return ResponseEntity
					.badRequest()
					.body(e.getMessage());
		}
		
	}
}
