package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "renewal", schema = "dbo")
@Data
public class Renewal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "renewalid")
    private Integer renewalid;

    // 來源方案：從哪一筆方案辦理續約
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "membercourseid", nullable = false)
    private Membercourse memberCourse;


    // 新方案：這次續約建立的方案
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "newmembercourseid",
            nullable = false,
            unique = true
    )
    private Membercourse newMemberCourse;

    @Column(name = "renewaldate")
    private LocalDateTime renewaldate;

    @Column(name = "addedsessions")
    private Integer addedsessions;

    @Column(name = "amount")
    private Integer amount;

    @org.hibernate.annotations.Nationalized
    @Column(name = "paymentmethod", length = 50)
    private String paymentmethod;

    @org.hibernate.annotations.Nationalized
    @Column(name = "note", length = 500)
    private String note;
}
