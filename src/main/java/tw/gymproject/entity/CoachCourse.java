package tw.gymproject.entity;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "coachid", insertable = false, updatable = false)
    private Coach coach;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "courseid", insertable = false, updatable = false)
    private Course course;
}
