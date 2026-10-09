package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

@Entity
@Table(name = "membercourse")
@Data
public class MemberCourse {

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

    @Column(name = "status", nullable = false)
    private String status;
}