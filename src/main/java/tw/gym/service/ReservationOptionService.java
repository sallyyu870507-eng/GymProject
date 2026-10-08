package tw.gym.service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import tw.gym.dto.MemberCourseDTO;
import tw.gym.dto.ScheduleOptionDTO;
import tw.gym.repository.BookingRepository;
import tw.gym.repository.ClassScheduleRepository;

@Service
public class ReservationOptionService {
	
	 private final BookingRepository bookingRepository;
	    private final ClassScheduleRepository classScheduleRepository;

	    public ReservationOptionService(
	            BookingRepository bookingRepository,
	            ClassScheduleRepository classScheduleRepository) {

	        this.bookingRepository = bookingRepository;
	        this.classScheduleRepository = classScheduleRepository;
	    }


    /* STEP1查會員已購買且還有剩餘堂數的課程
     * 還有課程相對應的教練 */
	    public List<MemberCourseDTO> getPurchasedCourses(Integer memberid) {

	        List<Object[]> results =
	                bookingRepository.findPurchasedCoursesByMemberid(memberid);

	        List<MemberCourseDTO> dtoList = new ArrayList<>();

	        for (Object[] row : results) {

	            MemberCourseDTO dto = new MemberCourseDTO();

	            dto.setMembercourseid(
	                    ((Number) row[0]).intValue()
	            );

	            dto.setCourseid(
	                    ((Number) row[1]).intValue()
	            );

	            dto.setCoursename(
	                    (String) row[2]
	            );

	            dto.setCoachid(
	                    ((Number) row[3]).intValue()
	            );

	            dto.setCoachname(
	                    (String) row[4]
	            );

	            dto.setRemainingsessions(
	                    ((Number) row[5]).intValue()
	            );

	            dtoList.add(dto);
	        }

	        return dtoList;
	    }
    
    /*STEP2依課程+教練找出可預約的日期*/
	    public List<LocalDate> getAvailableDatesByMemberCourse(
	            Integer memberid,
	            Integer membercourseid) {

	        List<Object[]> courseAndCoach =
	                bookingRepository
	                        .findCourseAndCoachByMembercourseidAndMemberid(
	                                membercourseid,
	                                memberid
	                        );

	        if (courseAndCoach.isEmpty()) {
	            throw new RuntimeException(
	                    "找不到這筆會員課程，或這筆課程不屬於目前登入會員"
	            );
	        }

	        Object[] row =
	                courseAndCoach.get(0);

	        Integer courseid =
	                ((Number) row[0]).intValue();

	        Integer coachid =
	                ((Number) row[1]).intValue();


	        List<java.sql.Date> results =
	                classScheduleRepository
	                        .findAvailableDates(
	                                courseid,
	                                coachid
	                        );

	        List<LocalDate> dateList =
	                new ArrayList<>();

	        for (java.sql.Date date : results) {

	            dateList.add(
	                    date.toLocalDate()
	            );
	        }

	        return dateList;
	    }

    
    /*STEP3 教練+課程+日期全時段*/
    
	    public List<ScheduleOptionDTO> getScheduleOptionsByMemberCourse(
	            Integer memberid,
	            Integer membercourseid,
	            LocalDate classdate) {

	        List<Object[]> courseAndCoach =
	                bookingRepository
	                        .findCourseAndCoachByMembercourseidAndMemberid(
	                                membercourseid,
	                                memberid
	                        );

	        if (courseAndCoach.isEmpty()) {
	            throw new RuntimeException(
	                    "找不到這筆會員課程，或這筆課程不屬於目前登入會員"
	            );
	        }

	        Object[] memberCourseRow =
	                courseAndCoach.get(0);

	        Integer courseid =
	                ((Number) memberCourseRow[0]).intValue();

	        Integer coachid =
	                ((Number) memberCourseRow[1]).intValue();


	        List<Object[]> results =
	                classScheduleRepository
	                        .findScheduleOptions(
	                                courseid,
	                                coachid,
	                                classdate
	                        );

	        List<ScheduleOptionDTO> dtoList =
	                new ArrayList<>();

	        for (Object[] row : results) {

	            ScheduleOptionDTO dto =
	                    new ScheduleOptionDTO();

	            dto.setScheduleid(
	                    ((Number) row[0]).intValue()
	            );

	            dto.setStarttime(
	                    ((java.sql.Time) row[1])
	                            .toLocalTime()
	            );

	            dto.setEndtime(
	                    ((java.sql.Time) row[2])
	                            .toLocalTime()
	            );

	            dto.setStatus(
	                    (String) row[3]
	            );

	            dtoList.add(dto);
	        }

	        return dtoList;
	    }
	}