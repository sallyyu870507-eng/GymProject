package tw.gymproject.entity;

//import java.math.BigDecimal;
import java.time.LocalDate;

//import org.springframework.data.relational.core.sql.FalseCondition;

//import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "membercourse")
//使用lombok
@Data
public class Membercourse {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer membercourseid;	
	
	private Integer totalsessions;
	
	private Integer remainingsessions;
	
	private LocalDate purchasedate;
	
	private String status;
	

//	@Column(name = "totalamount", precision = 12, scale = 2)
//	private BigDecimal totalamount;
	
	//----------//
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "memberid", nullable = false)
	private Member member;
	

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "coachid", nullable = false)
	private Coach coach;
	
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "courseid", nullable = false)
	private Course course;
	

	
}
