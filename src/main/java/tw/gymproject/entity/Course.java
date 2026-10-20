package tw.gymproject.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.math.BigDecimal;

@Entity
@Table(name = "course", schema = "dbo")
@Getter
@Setter
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Course {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "courseid")
    private Integer courseid;

    @Nationalized
    @Column(name = "coursename", nullable = false, length = 100)
    private String coursename;

    @Nationalized
    @Column(name = "coursetype", nullable = false, length = 50)
    private String coursetype;

    @Nationalized
    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "durationmin", nullable = false)
    private Integer durationmin = 60;

    @Column(name = "price", nullable = false,
            precision = 10, scale = 2)
    private BigDecimal price;

    @Nationalized
    @Column(name = "status", nullable = false, length = 20)
    private String status = "active";
}