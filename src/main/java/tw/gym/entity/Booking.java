package tw.gym.entity;


import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name="booking")
public class Booking {
	
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer bookingid;
	
	private Integer membercourseid;
	private Integer scheduleid;
	private LocalDateTime bookingtime;
	private String bookingstatus;
	private String note;
	private LocalDateTime updatetime;
	
	public Integer getBookingid() {
		return bookingid;
	}
	public void setBookingid(Integer bookingid) {
		this.bookingid = bookingid;
	}
	public Integer getMembercourseid() {
		return membercourseid;
	}
	public void setMembercourseid(Integer membercourseid) {
		this.membercourseid = membercourseid;
	}
	public Integer getScheduleid() {
		return scheduleid;
	}
	public void setScheduleid(Integer scheduleid) {
		this.scheduleid = scheduleid;
	}
	public LocalDateTime getBookingtime() {
		return bookingtime;
	}
	public void setBookingtime(LocalDateTime bookingtime) {
		this.bookingtime = bookingtime;
	}
	public String getBookingstatus() {
		return bookingstatus;
	}
	public void setBookingstatus(String bookingstatus) {
		this.bookingstatus = bookingstatus;
	}
	public String getNote() {
		return note;
	}
	public void setNote(String note) {
		this.note = note;
	}
	public LocalDateTime getUpdatetime() {
		return updatetime;
	}
	public void setUpdatetime(LocalDateTime updatetime) {
		this.updatetime = updatetime;
	}
	
	
}
	

