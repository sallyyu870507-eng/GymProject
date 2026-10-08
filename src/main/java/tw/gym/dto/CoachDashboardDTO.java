package tw.gym.dto;


public class CoachDashboardDTO {
	
	//教練端
	//2.3.今日課程數和學生數
	private Integer todayCourseCount;
	private Integer todayStudentCount;
	
	public Integer getTodayCourseCount() {
		return todayCourseCount;
	}
	public void setTodayCourseCount(Integer todayCourseCount) {
		this.todayCourseCount = todayCourseCount;
	}
	public Integer getTodayStudentCount() {
		return todayStudentCount;
	}
	public void setTodayStudentCount(Integer todayStudentCount) {
		this.todayStudentCount = todayStudentCount;
	}
	
	
}
