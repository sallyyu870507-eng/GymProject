package tw.gymproject.entity;

import java.time.LocalDateTime;

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
@Table(name = "booking", schema = "dbo")
@Getter
@Setter
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "bookingid")
    private Integer bookingid;

    // Main booking requests and services write these two FK columns.
    @Column(name = "membercourseid", nullable = false)
    private Integer membercourseid;

    @Column(name = "scheduleid", nullable = false)
    private Integer scheduleid;

    // Read-only associations support attendance and renewal query paths.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "membercourseid", insertable = false, updatable = false)
    private Membercourse membercourse;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "scheduleid", insertable = false, updatable = false)
    private ClassSchedule schedule;

    @Column(name = "bookingtime", nullable = false)
    private LocalDateTime bookingtime;

    @Nationalized
    @Column(name = "bookingstatus", nullable = false, length = 20)
    private String bookingstatus;

    @Nationalized
    @Column(name = "note", nullable = false, length = 100)
    private String note;

    @Column(name = "updatetime", nullable = false)
    private LocalDateTime updatetime;
}
