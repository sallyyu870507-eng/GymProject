package tw.gymproject.dto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class PurchaseCourseDTO {
	  Integer courseid;
	    String coursename;
	    BigDecimal price;

}
