package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "course")
@Data
public class Course {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "courseid")
    private Integer courseid;

    @Column(name = "coursename", nullable = false)
    private String coursename;

    @Column(name = "coursetype", nullable = false)
    private String coursetype;

    @Column(name = "description", nullable = false)
    private String description;

    @Column(name = "durationmin", nullable = false)
    private Integer durationmin;

    @Column(name = "price", nullable = false)
    private Integer price;

    @Column(
            name = "status",
            nullable = false,
            columnDefinition = "nchar(10)"
    )
    private String status;
}