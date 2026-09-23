package tw.gymproject.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

@Entity
@Table(name="coach")
public class Coach {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer coachid;
	
	private String coachno;
	
	private String name;
	
	private String gender;
	
	private String phone;
	
	public Integer getCoachid() {
		return coachid;
	}

	public void setCoachid(Integer coachid) {
		this.coachid = coachid;
	}


	public String getCoachno() {
		return coachno;
	}

	public void setCoachno(String coachno) {
		this.coachno = coachno;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getGender() {
		return gender;
	}

	public void setGender(String gender) {
		this.gender = gender;
	}

	public String getPhone() {
		return phone;
	}

	public void setPhone(String phone) {
		this.phone = phone;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getSpecialty() {
		return specialty;
	}

	public void setSpecialty(String specialty) {
		this.specialty = specialty;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	private String email;
	
	private String specialty;
	
	private String status;

	//---------//
	@OneToOne
	@MapsId
	@JoinColumn(name="accountid", nullable = false, unique = true)
	private Useraccount account;

	public Useraccount getAccount() {
		return account;
	}

	public void setAccount(Useraccount account) {
		this.account = account;
	}
	
	
	
}
