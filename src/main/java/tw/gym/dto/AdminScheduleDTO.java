package tw.gym.dto;

import java.time.LocalDate;
import java.time.LocalTime;

public class AdminScheduleDTO {
	//管理員端回傳當天所有教練的排課
	private Integer scheduleid;
	private Integer coachid;
	private String coachname;
	
	private LocalDate classdate;
	private LocalTime starttime;
	private LocalTime endtime;
	
	private String status;
	
	private String membername;
	private String coursename;
	public Integer getScheduleid() {
		return scheduleid;
	}
	public void setScheduleid(Integer scheduleid) {
		this.scheduleid = scheduleid;
	}
	public Integer getCoachid() {
		return coachid;
	}
	public void setCoachid(Integer coachid) {
		this.coachid = coachid;
	}
	public String getCoachname() {
		return coachname;
	}
	public void setCoachname(String coachname) {
		this.coachname = coachname;
	}
	public LocalDate getClassdate() {
		return classdate;
	}
	public void setClassdate(LocalDate classdate) {
		this.classdate = classdate;
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
	public String getStatus() {
		return status;
	}
	public void setStatus(String status) {
		this.status = status;
	}
	public String getMembername() {
		return membername;
	}
	public void setMembername(String membername) {
		this.membername = membername;
	}
	public String getCoursename() {
		return coursename;
	}
	public void setCoursename(String coursename) {
		this.coursename = coursename;
	}
	
	
	
	
	
}
