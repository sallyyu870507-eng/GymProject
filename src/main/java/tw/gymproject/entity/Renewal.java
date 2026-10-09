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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "membercourseid", nullable = false)
    private MemberCourse memberCourse;

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