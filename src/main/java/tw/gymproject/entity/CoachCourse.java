package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "coachcourse")
@Data
public class CoachCourse {

    @EmbeddedId
    private CoachCourseId id;

    @MapsId("coachid")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "coachid", nullable = false)
    private Coach coach;

    @MapsId("courseid")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "courseid", nullable = false)
    private Course course;
}