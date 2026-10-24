package tw.gymproject.entity;

import java.time.LocalDate;
import java.time.LocalTime;

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
@Table(name = "classschedule", schema = "dbo")
@Getter
@Setter
public class ClassSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "scheduleid")
    private Integer scheduleid;

    // Main schedule services write these FK columns.
    @Column(name = "coachid", nullable = false)
    private Integer coachid;

    @Column(name = "courseid", nullable = false)
    private Integer courseid;

    // Read-only associations support attendance and renewal query paths.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "coachid", insertable = false, updatable = false)
    private Coach coach;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "courseid", insertable = false, updatable = false)
    private Course course;

    @Column(name = "classdate", nullable = false)
    private LocalDate classdate;

    @Column(name = "starttime", nullable = false, columnDefinition = "time(0)")
    private LocalTime starttime;

    @Column(name = "endtime", nullable = false, columnDefinition = "time(0)")
    private LocalTime endtime;

    @Nationalized
    @Column(name = "classroom", nullable = false, length = 50)
    private String classroom;

    @Nationalized
    @Column(name = "status", nullable = false, length = 20)
    private String status;
}
