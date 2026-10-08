package tw.gym.dto;

public class MemberCourseDTO {
	
	//會員端
	//1.登入後顯示已購課程
	/*一個專門裝「會員已購課程資料」的盒子*/
	private Integer membercourseid;
	private Integer courseid;
	private String coursename;
	private Integer coachid;
	private String coachname;
	private Integer remainingsessions;
	public Integer getMembercourseid() {
		return membercourseid;
	}
	public void setMembercourseid(Integer membercourseid) {
		this.membercourseid = membercourseid;
	}
	public Integer getCourseid() {
		return courseid;
	}
	public void setCourseid(Integer courseid) {
		this.courseid = courseid;
	}
	public String getCoursename() {
		return coursename;
	}
	public void setCoursename(String coursename) {
		this.coursename = coursename;
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
	public Integer getRemainingsessions() {
		return remainingsessions;
	}
	public void setRemainingsessions(Integer remainingsessions) {
		this.remainingsessions = remainingsessions;
	}
	
	
}
