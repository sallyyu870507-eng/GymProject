package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "booking")
@Data
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "bookingid")
    private Integer bookingid;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "membercourseid", nullable = false)
    private MemberCourse membercourse;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "scheduleid", nullable = false)
    private ClassSchedule schedule;

    @Column(name = "bookingtime", nullable = false)
    private LocalDateTime bookingtime;

    @Column(name = "bookingstatus", nullable = false)
    private String bookingstatus;

    @Column(name = "note", nullable = false)
    private String note;

    @Column(name = "updatetime", nullable = false)
    private LocalDateTime updatetime;
}