package tw.gymproject.service;

import tw.gymproject.dto.CoachCreateRequest;
import tw.gymproject.entity.Coach;
import tw.gymproject.dao.CoachRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;
import org.springframework.data.domain.Sort;
import tw.gymproject.dto.CoachUpdateRequest;
import tw.gymproject.dto.CoachStatusRequest;
import tw.gymproject.dao.AccountRepository;
import org.mindrot.jbcrypt.BCrypt;
import tw.gymproject.entity.Useraccount;

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
        String name = request.getName().trim();
        String phone = request.getPhone().trim();

        // 教練英文名字作為登入帳號
        String username = name;

        // 檢查教練編號
        if (coachRepository.existsByCoachno(coachno)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "教練編號已存在"
            );
        }

        // 檢查所有角色的帳號，避免使用到既有帳號
        if (accountRepository.existsByUsername(username)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "此名字已被用作登入帳號，請使用其他名稱"
            );
        }

        // 建立教練帳號
        Useraccount account = new Useraccount();
        account.setUsername(username);

        // 初始密碼為電話，資料庫存 BCrypt 雜湊
        account.setPassword(
                BCrypt.hashpw(phone, BCrypt.gensalt())
        );

        account.setRole("coach");
        account.setStatus("active");

        Useraccount savedAccount = accountRepository.save(account);

        // 建立教練資料
        Coach coach = new Coach();
        coach.setCoachno(coachno);
        coach.setName(name);
        coach.setGender(request.getGender());
        coach.setPhone(phone);
        coach.setEmail(request.getEmail());
        coach.setSpecialty(request.getSpecialty());
        coach.setStatus("active");

        // 關聯剛建立的帳號
        coach.setAccount(savedAccount);

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

        Useraccount account = coach.getAccount();
        if (account != null) {
            account.setStatus(request.getStatus());
            accountRepository.save(account);
        }

        return coachRepository.save(coach);
    }

    @Transactional(readOnly = true)
    public Coach getCoachById(Integer coachid) {

        return coachRepository.findById(coachid)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "找不到此教練"));
    }
}