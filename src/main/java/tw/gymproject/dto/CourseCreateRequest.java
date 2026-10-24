package tw.gymproject.dto;

import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class CourseCreateRequest {

    @NotBlank(message = "課程名稱不可空白")
    @Size(max = 100, message = "課程名稱最多100個字元")
    private String coursename;

    @NotBlank(message = "課程類型不可空白")
    @Size(max = 50, message = "課程類型最多50個字元")
    private String coursetype;

    @Size(max = 500, message = "課程介紹最多500個字元")
    private String description;

    @NotNull(message = "價格不可省略")
    @DecimalMin(value = "0.00", message = "價格不可小於0")
    @Digits(integer = 8, fraction = 2,
            message = "價格最多8位整數及2位小數")
    private BigDecimal price;
}
