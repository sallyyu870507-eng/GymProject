package tw.gymproject.service;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Service;

import tw.gymproject.dao.CoachRepository;
import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.entity.Coach;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.exception.UnauthorizedException;

@Service
public class CoachSessionService {

    private final CoachRepository coachRepository;

    public CoachSessionService(
            CoachRepository coachRepository
    ) {
        this.coachRepository = coachRepository;
    }

    public Integer getCurrentCoachId(
            HttpSession session
    ) {
        if (session == null) {
            throw new UnauthorizedException(
                    "尚未登入或登入已失效"
            );
        }

        Object sessionUser = session.getAttribute("user");

        if (!(sessionUser instanceof LoginResultDTO user)) {
            throw new UnauthorizedException(
                    "尚未登入或登入已失效"
            );
        }

        if (!"coach".equalsIgnoreCase(user.getRole())) {
            throw new ForbiddenException(
                    "目前登入身分不是教練"
            );
        }

        Integer accountId = user.getAccountid();

        if (accountId == null) {
            throw new UnauthorizedException(
                    "登入資料不完整，請重新登入"
            );
        }

        Coach coach = coachRepository
                .findByAccount_Accountid(accountId)
                .orElseThrow(() ->
                        new ForbiddenException(
                                "找不到登入帳號對應的教練"
                        )
                );

        return coach.getCoachid();
    }
}