package tw.gymproject.entity;

import java.io.Serializable;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Embeddable
@Getter
@Setter
@NoArgsConstructor
@EqualsAndHashCode
public class CoachCourseId implements Serializable {

    @Column(name = "coachid")
    private Integer coachid;

    @Column(name = "courseid")
    private Integer courseid;

    public CoachCourseId(Integer coachid, Integer courseid) {
        this.coachid = coachid;
        this.courseid = courseid;
    }
}
