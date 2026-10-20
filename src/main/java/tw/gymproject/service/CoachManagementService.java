package tw.gymproject.service;

import tw.gymproject.dto.CoachCreateRequest;
import tw.gymproject.entity.Coach;
import tw.gymproject.repository.CoachRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;
import org.springframework.data.domain.Sort;
import tw.gymproject.dto.CoachUpdateRequest;
import tw.gymproject.dto.CoachStatusRequest;
import tw.gymproject.repository.AccountRepository;

@Service
public class CoachManagementService {

    private final CoachRepository coachRepository;
    private final AccountRepository accountRepository;

    public CoachManagementService(
            CoachRepository coachRepository,
            AccountRepository accountRepository) {
        this.coachRepository = coachRepository;
        this.accountRepository = accountRepository;
    }

    @Transactional
    public Coach createCoach(CoachCreateRequest request) {

        String coachno = request.getCoachno().trim();

        // 檢查教練編號是否重複
        if (coachRepository.existsByCoachno(coachno)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "教練編號已存在"
            );
        }

        Coach coach = new Coach();
        coach.setCoachno(coachno);
        coach.setName(request.getName().trim());
        coach.setGender(request.getGender());
        coach.setPhone(request.getPhone());
        coach.setEmail(request.getEmail());
        coach.setSpecialty(request.getSpecialty());
        coach.setStatus("active");

        coach.setAccount(
                accountRepository.findById(request.getAccountid())
                        .orElseThrow(() -> new ResponseStatusException(
                                HttpStatus.NOT_FOUND, "找不到此帳號"))
        );

        return coachRepository.save(coach);
    }

    @Transactional(readOnly = true)
    public List<Coach> getAllCoaches() {
        return coachRepository.findAll(
                Sort.by(Sort.Direction.ASC, "coachid")
        );
    }

    @Transactional
    public Coach updateCoach(
            Integer coachid,
            CoachUpdateRequest request) {

        // 查詢要修改的教練
        Coach coach = coachRepository.findById(coachid)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "找不到此教練"));

        String coachno = request.getCoachno().trim();

        // 檢查編號是否被其他教練使用
        if (coachRepository.existsByCoachnoAndCoachidNot(
                coachno, coachid)) {

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "教練編號已存在");
        }

        // 修改資料
        coach.setCoachno(coachno);
        coach.setName(request.getName().trim());
        coach.setGender(request.getGender());
        coach.setPhone(request.getPhone());
        coach.setEmail(request.getEmail());
        coach.setSpecialty(request.getSpecialty());

        return coachRepository.save(coach);
    }

    @Transactional
    public Coach updateCoachStatus(
            Integer coachid,
            CoachStatusRequest request) {

        Coach coach = coachRepository.findById(coachid)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "找不到此教練"));

        coach.setStatus(request.getStatus());

        return coachRepository.save(coach);
    }

    @Transactional(readOnly = true)
    public Coach getCoachById(Integer coachid) {

        return coachRepository.findById(coachid)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "找不到此教練"));
    }
}