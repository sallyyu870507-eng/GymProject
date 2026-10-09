package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "attendance",
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

    @Column(name = "attendancestatus", nullable = false)
    private String attendancestatus;

    @Column(name = "workoutfocus")
    private String workoutfocus;

    @Column(name = "note")
    private String note;

    @Column(name = "updatetime")
    private LocalDateTime updatetime;
}