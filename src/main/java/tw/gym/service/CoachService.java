package tw.gym.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import tw.gym.dto.CoachDashboardDTO;
import tw.gym.dto.CoachScheduleDTO;
import tw.gym.entity.Booking;
import tw.gym.repository.BookingRepository;
import tw.gym.repository.ClassScheduleRepository;


@Service
public class CoachService {
	//教練端service
	private final ClassScheduleRepository classScheduleRepository;
	private final BookingRepository bookingRepository;
	
	public CoachService(
	        ClassScheduleRepository classScheduleRepository,
	        BookingRepository bookingRepository) {

	    this.classScheduleRepository = classScheduleRepository;
	    this.bookingRepository = bookingRepository;
	}
	
	public List<CoachScheduleDTO> getBookedSchedules(
	        Integer coachid,
	        LocalDate classdate) {

	    // 去 Repository 查「這個教練、這一天」所有 booked 課程
	    List<Object[]> results =
	            classScheduleRepository
	                    .findBookedSchedulesByCoachAndDate(
	                            coachid,
	                            classdate
	                    );

	    // 準備 DTO List
	    List<CoachScheduleDTO> dtoList =
	            new ArrayList<>();

	    // 一筆一筆轉成 DTO
	    for (Object[] row : results) {

	        CoachScheduleDTO dto =
	                new CoachScheduleDTO();

	        // row[0] = bookingid
	        dto.setBookingid(
	                ((Number) row[0]).intValue()
	        );

	        // row[1] = scheduleid
	        dto.setScheduleid(
	                ((Number) row[1]).intValue()
	        );

	        // row[2] = coursename
	        dto.setCoursename(
	                (String) row[2]
	        );

	        // row[3] = studentname
	        dto.setStudentname(
	                (String) row[3]
	        );

	        // row[4] = starttime
	        dto.setStarttime(
	                ((java.sql.Time) row[4])
	                        .toLocalTime()
	        );

	        // row[5] = endtime
	        dto.setEndtime(
	                ((java.sql.Time) row[5])
	                        .toLocalTime()
	        );

	        dtoList.add(dto);
	    }

	    return dtoList;
	}
	
	/* 查教練某一天的首頁統計資料 */
	
	public CoachDashboardDTO getDashboard(
			Integer coachid,
			LocalDate classdate) {
		
		Integer todayCourseCount =
				classScheduleRepository
				.countTodayCourses(coachid, classdate);
		
		Integer todayStudentCount =
				classScheduleRepository
				.countTodayStudent(coachid, classdate);
		
		CoachDashboardDTO dto=
				new CoachDashboardDTO();
		
		dto.setTodayCourseCount(todayCourseCount);
		dto.setTodayStudentCount(todayStudentCount);
		
		return dto;
	}
	
	/*教練代取消課程*/
	public String cancelBookingByCoach(
    		Integer bookingid, Integer coachid) {
    	
    	//1.先確認這筆預約是不是教練的課
    	int count =
    			bookingRepository.countBookingByCoach(bookingid, coachid);
    	
    	if(count==0) {
    		throw new RuntimeException(
    				"找不到此筆預約，或此預約不屬於目前的教練");
    	}
    	
    	//2.找到這筆預約
    	Booking booking =
    			bookingRepository.findById(bookingid)
    			.orElseThrow(
    					()->new RuntimeException("找不到此筆預約"));
    	
    	//3.只有booked可以取消
    	if (!"booked".equals(booking.getBookingstatus())) {
    		throw new RuntimeException(
    				"此預約目前無法取消");
		}
    	//4.改狀態
    	booking.setBookingstatus("cancelled");
    	
    	//5.更新最後修改時間
    	booking.setUpdatetime(LocalDateTime.now());
    	
    	//6.存回資料庫
    	bookingRepository.save(booking);
    	
    	return"教練代取消成功";
    }
}
	

