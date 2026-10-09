package tw.gymproject.dto;

import lombok.Data;

@Data
public class RenewalRequest {

    private Integer addedSessions;

    private Integer amount;

    private String paymentMethod;

    private String note;
}