package tw.gymproject.entity;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import org.springframework.format.annotation.DateTimeFormat;

@Entity
@Table(name = "member", schema = "dbo")
@Getter
@Setter
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "memberid")
    private Integer memberid;

    @JsonIgnore
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "accountid", nullable = false, unique = true)
    private Useraccount account;

    @Nationalized
    @Column(name = "memberno", length = 20)
    private String memberno;

    @Nationalized
    @Column(name = "name", nullable = false, length = 50)
    private String name;

    @Nationalized
    @Column(name = "gender", nullable = false, length = 10)
    private String gender;

    @Nationalized
    @Column(name = "phone", nullable = false, length = 50)
    private String phone;

    @Nationalized
    @Column(name = "email", nullable = false, length = 100)
    private String email;

    @Column(name = "birthday", nullable = false)
	@DateTimeFormat(pattern = "yyyy-MM-dd")
    private LocalDate birthday;

    @Nationalized
    @Column(name = "avatarurl", length = 500)
    private String avatarurl;

    @Nationalized
    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @JsonIgnore
    @OneToMany(mappedBy = "member", fetch = FetchType.LAZY)
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
