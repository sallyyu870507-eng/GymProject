package tw.gymproject.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;

@Entity
@Table(name = "coach", schema = "dbo")
@Getter
@Setter
public class Coach {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "coachid")
    private Integer coachid;

    @Nationalized
    @Column(name = "coachno", nullable = false, length = 20)
    private String coachno;

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

    @Nationalized
    @Column(name = "specialty", nullable = false, length = 100)
    private String specialty;

    @Nationalized
    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @JsonIgnore
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "accountid", nullable = false, unique = true)
    private Useraccount account;

    public Integer getAccountid() {
        return account == null ? null : account.getAccountid();
    }
}
