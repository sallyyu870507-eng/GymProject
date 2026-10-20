package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "renewal")
@Data
public class Renewal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "renewalid")
    private Integer renewalid;

    // 來源方案：從哪一筆方案辦理續約
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "membercourseid", nullable = false)
    private MemberCourse memberCourse;


    // 新方案：這次續約建立的方案
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "newmembercourseid",
            nullable = false,
            unique = true
    )
    private MemberCourse newMemberCourse;

    @Column(name = "renewaldate")
    private LocalDateTime renewaldate;

    @Column(name = "addedsessions")
    private Integer addedsessions;

    @Column(name = "amount")
    private Integer amount;

    @Column(name = "paymentmethod")
    private String paymentmethod;

    @Column(name = "note")
    private String note;
}