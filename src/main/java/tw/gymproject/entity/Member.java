package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

@Entity
@Table(name = "member")
@Data
public class Member {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "memberid")
	private Integer memberid;

	@OneToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "accountid", nullable = false, unique = true)
	private Useraccount account;

	@Column(name = "memberno", nullable = false)
	private String memberno;

	@Column(name = "name", nullable = false)
	private String name;

	@Column(name = "gender", nullable = false)
	private String gender;

	@Column(name = "phone", nullable = false)
	private String phone;

	@Column(name = "email", nullable = false)
	private String email;

	@Column(name = "birthday", nullable = false)
	private LocalDate birthday;

	@Column(name = "status", nullable = false)
	private String status;

	@Column(name = "avatarurl")
	private String avatarurl;
}