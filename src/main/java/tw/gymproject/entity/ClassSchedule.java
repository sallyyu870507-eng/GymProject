package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Table(name = "classschedule")
@Data
public class ClassSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "scheduleid")
    private Integer scheduleid;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "coachid", nullable = false)
    private Coach coach;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "courseid", nullable = false)
    private Course course;

    @Column(name = "classdate", nullable = false)
    private LocalDate classdate;

    @Column(name = "starttime", nullable = false)
    private LocalTime starttime;

    @Column(name = "endtime", nullable = false)
    private LocalTime endtime;

    @Column(name = "classroom", nullable = false)
    private String classroom;

    @Column(name = "status", nullable = false)
    private String status;
}