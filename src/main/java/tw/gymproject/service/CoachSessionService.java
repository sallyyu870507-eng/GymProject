package tw.gymproject.service;

import org.springframework.stereotype.Service;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dao.CoachRepository;
import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.entity.Coach;
import tw.gymproject.exception.ForbiddenException;

@Service
public class CoachSessionService {

    private final CoachRepository coachRepository;

    public CoachSessionService(
            CoachRepository coachRepository
    ) {
        this.coachRepository =
                coachRepository;
    }


    public Integer getCurrentCoachId(
            HttpSession session
    ) {

        LoginResultDTO user =
                (LoginResultDTO)
                        session.getAttribute("user");


        if (user == null) {
            throw new ForbiddenException(
                    "尚未登入"
            );
        }


        if (!"coach".equalsIgnoreCase(
                user.getRole()
        )) {
            throw new ForbiddenException(
                    "目前登入身分不是教練"
            );
        }


        Integer accountId =
                user.getAccountid();


        if (accountId == null) {
            throw new ForbiddenException(
                    "登入帳號資料不完整"
            );
        }


        Coach coach =
                coachRepository
                        .findByAccount_Accountid(
                                accountId
                        )
                        .orElseThrow(
                                () ->
                                        new ForbiddenException(
                                                "找不到登入帳號對應的教練"
                                        )
                        );


        return coach.getCoachid();
    }
}