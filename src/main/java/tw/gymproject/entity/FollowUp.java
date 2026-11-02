package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "followup", schema = "dbo")
@Data
public class FollowUp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "followupid")
    private Integer followupid;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "membercourseid", nullable = false)
    private Membercourse memberCourse;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "coachid", nullable = false)
    private Coach coach;

    @org.hibernate.annotations.Nationalized
    @Column(name = "status", length = 20)
    private String status;

    @Column(name = "note", columnDefinition = "nvarchar(max)")
    private String note;

    @Column(name = "createdate")
    private LocalDateTime createdate;

    @org.hibernate.annotations.Nationalized
    @Column(name = "contactmethod", length = 20)
    private String contactmethod;
}
