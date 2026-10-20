package tw.gymproject.service;

import org.mindrot.jbcrypt.BCrypt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import jakarta.transaction.Transactional;
import tw.gymproject.dao.AccountRepository;
import tw.gymproject.dao.CoachRepository;
import tw.gymproject.dao.MemberRepository;
import tw.gymproject.dto.CoachRegisterDTO;
import tw.gymproject.dto.RegisterDTO;
import tw.gymproject.entity.Coach;
import tw.gymproject.entity.Useraccount;

@Transactional
@Service
public class CoachService {


    private final AccountRepository repository ;
    private final MemberRepository memberRepository;
    private final CoachRepository coachRepository;

    public CoachService(AccountRepository repository,MemberRepository memberRepository,CoachRepository coachRepository) {
        this.repository=repository;
        this.memberRepository=memberRepository;
        this.coachRepository=coachRepository;
    }

    //註冊教練帳號
    public boolean registerCoach(CoachRegisterDTO coachDTO) {

        if(!repository.existsByUsername(coachDTO.getUsername())) {

            Useraccount account = new Useraccount();
            account.setUsername(coachDTO.getUsername());
            account.setPassword(BCrypt.hashpw(coachDTO.getPassword(), BCrypt.gensalt()));
            account.setRole("coach");
            account.setStatus("active");

            Useraccount savedAccCoach = repository.save(account);
            System.out.println(savedAccCoach.getUsername());
            //--教練個資
            Coach coach = new Coach();
            coach.setAccount(savedAccCoach);  //直接帶入剛剛存好的帳號資料
            coach.setName(coachDTO.getName());
            coach.setGender(coachDTO.getGender());
            coach.setPhone(coachDTO.getPhone());
            coach.setEmail(coachDTO.getEmail());
            coach.setSpecialty(coachDTO.getSpecialty());
            coach.setStatus("active");

            Coach savedCoach = coachRepository.save(coach);
            //System.out.println("還沒有編號:" + savedMember);
            //先完成儲存member有自動生成的ID之後，拿ID當作尾數放入會員編號
            //也可以一開始就設定在資料庫讓他去執行編號的編碼
            String coachCode = String.format("C%06d", savedCoach.getCoachid());
            savedCoach.setCoachno(coachCode);

            coachRepository.save(savedCoach);
            return true;
        }else {
            return false;
        }
    }

}