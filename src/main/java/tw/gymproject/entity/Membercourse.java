package tw.gymproject.entity;

import java.time.LocalDate;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;

@Entity
@Table(name = "membercourse", schema = "dbo")
@Getter
@Setter
public class Membercourse {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "membercourseid")
    private Integer membercourseid;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "memberid", nullable = false)
    private Member member;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "courseid", nullable = false)
    private Course course;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "coachid", nullable = false)
    private Coach coach;

    @Column(name = "purchasedate", nullable = false)
    private LocalDate purchasedate;

    @Column(name = "totalsessions", nullable = false)
    private Integer totalsessions;

    @Column(name = "remainingsessions", nullable = false)
    private Integer remainingsessions;

    @Nationalized
    @Column(name = "status", nullable = false, length = 20)
    private String status;
}
