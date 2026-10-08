package tw.gym.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
}
