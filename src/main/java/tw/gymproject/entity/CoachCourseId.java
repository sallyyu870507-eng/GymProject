package tw.gymproject.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.Data;

import java.io.Serializable;

@Embeddable
@Data
public class CoachCourseId implements Serializable {

    @Column(name = "coachid")
    private Integer coachid;

    @Column(name = "courseid")
    private Integer courseid;
}