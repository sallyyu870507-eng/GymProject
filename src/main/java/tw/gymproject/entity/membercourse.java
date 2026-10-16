package tw.gymproject.entity;

import java.time.LocalDate;

import org.springframework.data.relational.core.sql.FalseCondition;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "membercourse")
//使用lombok
public class membercourse {
	@Id
	private Integer membercourseid;	
	
	private Integer courseid;
	
	private Integer totalsessions;
	
	private Integer remainingsessions;
	
	private LocalDate purchasedate;
	private String status;
	
	
	
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



	public Integer getTotalsessions() {
		return totalsessions;
	}



	public void setTotalsessions(Integer totalsessions) {
		this.totalsessions = totalsessions;
	}



	public Integer getRemainingsessions() {
		return remainingsessions;
	}



	public void setRemainingsessions(Integer remainingsessions) {
		this.remainingsessions = remainingsessions;
	}



	public LocalDate getPurchasedate() {
		return purchasedate;
	}



	public void setPurchasedate(LocalDate purchasedate) {
		this.purchasedate = purchasedate;
	}



	public String getStatus() {
		return status;
	}


	public void setStatus(String status) {
		this.status = status;
	}


	//----------//
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "memberid", nullable = false, unique = true)
	private Member member;
	
	public Member getMember() {
		return member;
	}


	public void setMember(Member member) {
		this.member = member;
	}

	
}
