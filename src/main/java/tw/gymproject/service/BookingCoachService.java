package tw.gymproject.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import tw.gymproject.dto.CoachDashboardDTO;
import tw.gymproject.dto.CoachScheduleDTO;
import tw.gymproject.entity.Booking;
import tw.gymproject.entity.ClassSchedule;
import tw.gymproject.repository.BookingRepository;
import tw.gymproject.repository.ClassScheduleRepository;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import tw.gymproject.dto.CoachDashboardDTO;
import tw.gymproject.dto.CoachScheduleDTO;
import tw.gymproject.entity.Booking;
import tw.gymproject.repository.BookingRepository;
import tw.gymproject.repository.ClassScheduleRepository;


@Service
public class BookingCoachService {
	//教練端service
	private final ClassScheduleRepository classScheduleRepository;
	private final BookingRepository bookingRepository;
	
	public BookingCoachService(
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
	/* 教練修改預約日期與時間 */
    public String rescheduleBookingByCoach(
            Integer bookingid,
            Integer coachid,
            Integer newScheduleid) {

        // 1. 確認 booking 是不是目前教練的課
        int count =
                bookingRepository
                        .countBookingByCoach(
                                bookingid,
                                coachid
                        );

        if (count == 0) {
            throw new RuntimeException(
                    "找不到此預約，或此預約不屬於目前教練"
            );
        }


        // 2. 找原本 booking
        Booking booking =
                bookingRepository
                        .findById(bookingid)
                        .orElseThrow(
                                () -> new RuntimeException(
                                        "找不到此筆預約"
                                )
                        );


        // 3. 只有 booked 可以修改
        if (!"booked".equals(
                booking.getBookingstatus()
        )) {

            throw new RuntimeException(
                    "此預約目前無法修改"
            );
        }


        // 4. 找原本課表
        ClassSchedule oldSchedule =
                classScheduleRepository
                        .findById(
                                booking.getScheduleid()
                        )
                        .orElseThrow(
                                () -> new RuntimeException(
                                        "找不到原本課表"
                                )
                        );


        // 5. 今天可以修改
        //    只有今天以前不能修改
        if (oldSchedule
                .getClassdate()
                .isBefore(LocalDate.now())) {

            throw new RuntimeException(
                    "今天以前的預約無法修改"
            );
        }


        // 6. 找新的課表
        ClassSchedule newSchedule =
                classScheduleRepository
                        .findById(
                                newScheduleid
                        )
                        .orElseThrow(
                                () -> new RuntimeException(
                                        "找不到新的課表"
                                )
                        );


        // 7. 新日期可以是今天
        //    但不能是今天以前
        if (newSchedule
                .getClassdate()
                .isBefore(LocalDate.now())) {

            throw new RuntimeException(
                    "新的預約日期不能是今天以前"
            );
        }


        // 8. 不能改成完全相同的 schedule
        if (booking
                .getScheduleid()
                .equals(newScheduleid)) {

            throw new RuntimeException(
                    "新的日期時間與原本預約相同"
            );
        }


        // 9. 課程不能換
        if (!oldSchedule
                .getCourseid()
                .equals(
                        newSchedule.getCourseid()
                )) {

            throw new RuntimeException(
                    "修改預約時不能更換課程"
            );
        }


        // 10. 教練不能換
        if (!oldSchedule
                .getCoachid()
                .equals(
                        newSchedule.getCoachid()
                )) {

            throw new RuntimeException(
                    "修改預約時不能更換教練"
            );
        }


        // 11. 新時段也必須屬於目前登入教練
        if (!coachid.equals(
                newSchedule.getCoachid()
        )) {

            throw new RuntimeException(
                    "新的時段不屬於目前教練"
            );
        }


        // 12. 新時段必須 open
        if (!"open".equals(
                newSchedule.getStatus()
        )) {

            throw new RuntimeException(
                    "新的時段目前無法預約"
            );
        }


        // 13. 新時段不能已經有人 booked
        boolean alreadyBooked =
                bookingRepository
                        .existsByScheduleidAndBookingstatus(
                                newScheduleid,
                                "booked"
                        );

        if (alreadyBooked) {

            throw new RuntimeException(
                    "新的時段已經被其他會員預約"
            );
        }


        // 14. 修改 scheduleid
        booking.setScheduleid(
                newScheduleid
        );


        // 15. 更新修改時間
        booking.setUpdatetime(
                LocalDateTime.now()
        );


        // 16. 存回資料庫
        bookingRepository.save(
                booking
        );


        return "教練修改預約日期時間成功";
    }

}
	

