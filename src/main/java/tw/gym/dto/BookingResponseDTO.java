package tw.gym.dto;


import java.time.LocalDate;
import java.time.LocalTime;

public class BookingResponseDTO {
	
		//會員端
		//5.最後一步預約成功
	    private Integer bookingid;
	    private String coursename;
	    private String coachname;
	    private LocalDate classdate;
	    private LocalTime starttime;
	    private LocalTime endtime;
	    private String classroom;
	    private String bookingstatus;
		public Integer getBookingid() {
			return bookingid;
		}
		public void setBookingid(Integer bookingid) {
			this.bookingid = bookingid;
		}
		public String getCoursename() {
			return coursename;
		}
		public void setCoursename(String coursename) {
			this.coursename = coursename;
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
		public String getClassroom() {
			return classroom;
		}
		public void setClassroom(String classroom) {
			this.classroom = classroom;
		}
		public String getBookingstatus() {
			return bookingstatus;
		}
		public void setBookingstatus(String bookingstatus) {
			this.bookingstatus = bookingstatus;
		}
	    
	    
}
