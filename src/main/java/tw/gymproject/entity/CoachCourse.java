package tw.gymproject.entity;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "coachcourse", schema = "dbo")
@Getter
@Setter
@NoArgsConstructor
public class CoachCourse {

    @EmbeddedId
    private CoachCourseId id;

    public CoachCourse(Integer coachid, Integer courseid) {
        this.id = new CoachCourseId(coachid, courseid);
    }
}