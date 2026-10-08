package tw.gym.service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import tw.gym.dto.CoachDashboardDTO;
import tw.gym.dto.CoachScheduleDTO;
import tw.gym.repository.ClassScheduleRepository;

@Service
public class CoachService {
	//教練端service
	private final ClassScheduleRepository classScheduleRepository;
	
	public CoachService(
			ClassScheduleRepository classScheduleRepository) {
		this.classScheduleRepository=classScheduleRepository;
	}
	
	public List<CoachScheduleDTO> getBookedSchedules(
			Integer coachid,
			java.time.LocalDate classdate){
		
		/*去 Repository 查「這個教練、這一天」所有 booked 課程。*/
		List<Object[]> results =
				classScheduleRepository
				.findBookedSchedulesByCoachAndDate(
						coachid, classdate);
		
		/*準備一個空箱子dtoList*/
		List<CoachScheduleDTO> dtoList =
				new ArrayList<>();
		
		/*一筆一筆拿出去*/
		for(Object[] row: results) {
			
			CoachScheduleDTO dto =
					new CoachScheduleDTO();
			
			dto.setScheduleid(
					((Number) row[0]).intValue());
			
			dto.setCoursename((String) row[1]);
			
			dto.setStudentname((String) row[2]);
			
			dto.setStarttime(
					((java.sql.Time) row[3])
					.toLocalTime());
			
			dto.setEndtime(
					((java.sql.Time) row[4])
					.toLocalTime());
			
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
	
	
}
	

