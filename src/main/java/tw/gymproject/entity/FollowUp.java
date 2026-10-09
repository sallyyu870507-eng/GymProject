package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "followup")
@Data
public class FollowUp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "followupid")
    private Integer followupid;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "membercourseid", nullable = false)
    private MemberCourse memberCourse;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "coachid", nullable = false)
    private Coach coach;

    @Column(name = "status")
    private String status;

    @Column(name = "note")
    private String note;

    @Column(name = "createdate")
    private LocalDateTime createdate;

    @Column(name = "contactmethod")
    private String contactmethod;
}