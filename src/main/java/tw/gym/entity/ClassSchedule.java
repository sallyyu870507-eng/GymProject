package tw.gym.entity;

import java.time.LocalDate;
import java.time.LocalTime;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name="classschedule")
public class ClassSchedule {
	
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer scheduleid;
	
	private Integer coachid;
	private Integer courseid;
	private LocalDate classdate;
	private LocalTime starttime;
	private LocalTime endtime;
	private String classroom;
	private String status;
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
	public Integer getCourseid() {
		return courseid;
	}
	public void setCourseid(Integer courseid) {
		this.courseid = courseid;
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
	public String getClassroom() {
		return classroom;
	}
	public void setClassroom(String classroom) {
		this.classroom = classroom;
	}
	public String getStatus() {
		return status;
	}
	public void setStatus(String status) {
		this.status = status;
	}
	
	
	
	
}
