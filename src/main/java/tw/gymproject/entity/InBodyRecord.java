package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "inbodyrecords")
@Data
public class InBodyRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "inbodyid")
    private Integer inbodyid;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "memberid", nullable = false)
    private Member member;

    //一次上課->最多一份 InBody
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "attendanceid",
            nullable = false,
            unique = true
    )
    private Attendance attendance;

    @Column(name = "recorddate")
    private LocalDate recorddate;

    @Column(name = "weight", precision = 5, scale = 2)
    private BigDecimal weight;

    @Column(name = "bodyfatpct", precision = 4, scale = 1)
    private BigDecimal bodyfatpct;

    @Column(name = "musclemass", precision = 4, scale = 1)
    private BigDecimal musclemass;
}