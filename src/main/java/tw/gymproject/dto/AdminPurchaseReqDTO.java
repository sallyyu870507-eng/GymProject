package tw.gymproject.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data

public class AdminPurchaseReqDTO {
	
	  @NotNull(message = "請選擇課程")
	  Integer courseid;

	  @NotNull(message = "請選擇教練")
	  Integer coachid;

}
