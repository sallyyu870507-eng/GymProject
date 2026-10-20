package tw.gymproject.entity;

import java.time.LocalDate;

import java.util.ArrayList;
import java.util.List;

import org.hibernate.annotations.SQLDelete;
import org.springframework.format.annotation.DateTimeFormat;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;

import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

@Table(name = "member")
////如果要執行delete但希望SQL執行非DELETE的指令可以在這邊加上要客製的指令
//@SQLDelete(sql = "UPDATE member SET status = 'inactive' WHERE memberid = ?")
@Entity
public class Member {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer memberid;
	private String memberno;//
	private String name;//
	private String gender;
	private String phone;//
	private String email;
//	private String avatarurl; //照片檔案路徑
	
	@DateTimeFormat(pattern = "yyyy-MM-dd") //以免自動轉換失效
	private LocalDate birthday;
	private String status = "active" ;
	
	public Integer getMemberid() {
		return memberid;
	}
	public void setMemberid(Integer memberid) {
		this.memberid = memberid;
	}
	public String getMemberno() {
		return memberno;
	}
	public void setMemberno(String memberno) {
		this.memberno = memberno;
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
	public LocalDate getBirthday() {
		return birthday;
	}
	public void setBirthday(LocalDate birthday) {
		this.birthday = birthday;
	}
	public String getStatus() {
		return status;
	}
	public void setStatus(String status) {
		this.status = status;
	}
	
	
	//-----//
	@OneToOne
	@JoinColumn(name = "accountid", nullable=false, unique=true)
	private Useraccount account;
	public Useraccount getAccount() {
		return account;
	}
	public void setAccount(Useraccount account) {
		this.account = account;
	}

	//與學員擁有的課堂數量membercourse關係
	//查此One entity資料時，連接的關聯表Many內資料等到確定有呼叫.get...()功能時才撈出來，ToMnay表時建議
	@OneToMany(mappedBy = "member")
	//用陣列裝很多個課程資料
	private List<Membercourse> membercourses = new ArrayList<>();
	
	public List<Membercourse> getMembercourse() {
		return membercourses;
	}
	public void setMembercourse(List<Membercourse> membercourse) {
		this.membercourses = membercourse;
	}
	
	
	public void addcourse(Membercourse course) {
		if (course != null) {
			membercourses.add(course);
			course.setMember(this);
		}
	}
	
}
