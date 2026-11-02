package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "attendance", schema = "dbo",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "UQ_attendance_bookingid",
                        columnNames = "bookingid"
                )
        }
)
@Data
public class Attendance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "attendanceid")
    private Integer attendanceid;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bookingid", nullable = false, unique = true)
    private Booking booking;

    @Column(name = "checkintime")
    private LocalDateTime checkintime;

    @org.hibernate.annotations.Nationalized
    @Column(name = "attendancestatus", nullable = false, length = 50)
    private String attendancestatus;

    @org.hibernate.annotations.Nationalized
    @Column(name = "workoutfocus", length = 50)
    private String workoutfocus;

    @org.hibernate.annotations.Nationalized
    @Column(name = "note", length = 100)
    private String note;

    @Column(name = "updatetime")
    private LocalDateTime updatetime;
}
