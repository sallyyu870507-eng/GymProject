package tw.gymproject.entity;

import java.math.BigDecimal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.Nationalized;
import lombok.Getter;
import lombok.Setter;

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
    @Column(name = "description", nullable = false, columnDefinition = "nvarchar(max)")
    private String description;

    @Column(name = "durationmin", nullable = false)
    private Integer durationmin = 60;

    @Column(name = "price", nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Nationalized
    @Column(name = "status", nullable = false, length = 20)
    private String status = "active";
}
