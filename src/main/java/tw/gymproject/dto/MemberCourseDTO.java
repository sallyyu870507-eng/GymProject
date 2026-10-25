package tw.gymproject.dto;

import lombok.Data;

@Data
public class MemberCourseDTO {
	private Integer courseid;
	private String coursename;
	private Integer coachid;
	private String name; //教練名字
	private Integer remainingsessions;
	
	

}
