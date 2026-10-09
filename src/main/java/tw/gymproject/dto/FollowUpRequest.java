package tw.gymproject.dto;

import lombok.Data;

@Data
public class FollowUpRequest {

    private String status;

    private String contactMethod;

    private String note;
}