package tw.gymproject.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.Nationalized;

@Entity
@Table(name = "useraccount", schema = "dbo")
@SQLDelete(sql = "UPDATE useraccount SET status = 'inactive' WHERE accountid = ?")
@Getter
@Setter
public class Useraccount {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "accountid")
    private Integer accountid;

    @Nationalized
    @Column(name = "username", nullable = false, length = 50)
    private String username;

    @JsonIgnore
    @Nationalized
    @Column(name = "password", nullable = false, length = 200)
    private String password;

    @Nationalized
    @Column(name = "role", nullable = false, length = 50)
    private String role;

    @Nationalized
    @Column(name = "status", nullable = false, length = 50)
    private String status = "active";

    @OneToOne(mappedBy = "account", cascade = CascadeType.ALL)
    private Coach coach;

    @OneToOne(mappedBy = "account", cascade = CascadeType.ALL)
    private Member member;

    public void setCoach(Coach coach) {
        this.coach = coach;
        if (coach != null) {
            coach.setAccount(this);
        }
    }

    public void setMember(Member member) {
        this.member = member;
        if (member != null) {
            member.setAccount(this);
        }
    }
}
