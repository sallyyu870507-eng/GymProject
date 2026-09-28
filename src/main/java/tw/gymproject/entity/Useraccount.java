package tw.gymproject.entity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;


@Entity
@Table
public class Useraccount {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer accountid;
	
	private String username; //暫定為電話號碼

	private String password;
	
	private String role;
	
	private String status;

	public Integer getAccountid() {
		return accountid;
	}

	public void setAccountid(Integer accountid) {
		this.accountid = accountid;
	}

	public String getUsername() {
		return username;
	}

	public void setUsername(String username) {
		this.username = username;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public String getRole() {
		return role;
	}

	public void setRole(String role) {
		this.role = role;
	}

	public String getSatus() {
		return status;
	}

	public void setSatus(String satus) {
		this.status = satus;
	}

	//--------------//
	@OneToOne(mappedBy = "account", cascade = CascadeType.ALL)
	private Coach coach;
	
	@OneToOne(mappedBy = "account", cascade = CascadeType.ALL)
	private Member member;

	public Coach getCoach() {
		return coach;
	}

	public void setCoach(Coach coach) {
		this.coach = coach;
		if(coach != null) {
			//在coach端也建立account的資料，雙向
			coach.setAccount(this);
		}
	}

	public Member getMember() {
		return member;
	}

	public void setMember(Member member) {
		this.member = member;
		if(member != null) {
			member.setAccount(this);
		}
	}
	
	
}
