package tw.gym.dto;

import java.time.LocalTime;

public class ScheduleOptionDTO {
	
	//會員端
	//3.選日期顯示後的時間
	private Integer scheduleid;
	private LocalTime starttime;
	private LocalTime endtime;
	private String status;
	public Integer getScheduleid() {
		return scheduleid;
	}
	public void setScheduleid(Integer scheduleid) {
		this.scheduleid = scheduleid;
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
	
	
	
}
