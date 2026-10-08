package tw.gym.dto;

import java.time.LocalTime;

public class CoachScheduleDTO {
	//教練端
	//1.教練指定日期的已預約課表
	private Integer scheduleid;
	private String coursename;
	private String studentname;
	private LocalTime starttime;
	private LocalTime endtime;
	
	public Integer getScheduleid() {
		return scheduleid;
	}
	public void setScheduleid(Integer scheduleid) {
		this.scheduleid = scheduleid;
	}
	public String getCoursename() {
		return coursename;
	}
	public void setCoursename(String coursename) {
		this.coursename = coursename;
	}
	public String getStudentname() {
		return studentname;
	}
	public void setStudentname(String studentname) {
		this.studentname = studentname;
	}
	public LocalTime getStarttime() {
		return starttime;
	}
	public void setStarttime(LocalTime starttime) {
		this.starttime = starttime;
	}
	public LocalTime getEndtime() {
		return endtime;
	}
	public void setEndtime(LocalTime endtime) {
		this.endtime = endtime;
	}
}
