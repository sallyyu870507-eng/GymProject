package tw.gymproject.dto;

import java.time.LocalDate;
import java.util.List;

import lombok.Data;

@Data
public class MemberListDTO {

    private Integer memberid;
    private String memberno;//
    private String name;
    private String gender;
    private String phone;

    //代表每一位會員可以有多筆剩餘課堂
    private List<MemberCourseDTO> courses;


}



/*預期給前端的格式，雙層
 [
  {
    "memberid": 1001,
    "name": "王小明",
    "phone": "0912345678",
    "email": "ming@gmail.com",
    "courses": [
      {
        "coursename": "瑜珈",
        "remainingsessions": 8
      },
      {
        "coursename": "重量訓練",
        "remainingsessions": 5
      }
    ]
  }
]
*/