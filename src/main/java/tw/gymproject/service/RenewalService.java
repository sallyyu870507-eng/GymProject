package tw.gymproject.service;

/*
1. INSERT renewal -> 建立一筆 renewal 紀錄
        +
2. UPDATE membercourse -> 把 MemberCourse 的總堂數、剩餘堂數一起增加(呼叫 MemberCourseService.addSessions() 增加堂數)

Service 流程
createRenewal(...)
        ↓
檢查堂數是否合法
        ↓
檢查金額是否合法
        ↓
找到 MemberCourse
        ↓
建立 Renewal Entity
        ↓
renewalRepo.save()
        ↓
MemberCourseService.addSessions()
        ↓
堂數一起增加
*/

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.gymproject.entity.MemberCourse;
import tw.gymproject.entity.Renewal;
import tw.gymproject.repository.RenewalRepo;
import tw.gymproject.dto.RenewalRequest;

import java.time.LocalDateTime;

@Service
public class RenewalService {

    private final RenewalRepo renewalRepo;
    private final MemberCourseService memberCourseService;

    public RenewalService(
            RenewalRepo renewalRepo,
            MemberCourseService memberCourseService
    ) {
        this.renewalRepo = renewalRepo;
        this.memberCourseService = memberCourseService;
    }

    //整個方法是一筆完整交易，要嘛全部成功，要嘛全部失敗
    @Transactional
    public Renewal createRenewal(
            Integer memberCourseId,
            RenewalRequest request
    ) {

        if (request.getAddedSessions() == null
                || request.getAddedSessions() <= 0) {
            throw new RuntimeException("續約堂數必須大於 0");
        }

        if (request.getAmount() == null
                || request.getAmount() < 0) {
            throw new RuntimeException("續約金額不能小於 0");
        }

        MemberCourse memberCourse =
                memberCourseService.getById(memberCourseId);

        //把新建立的Renewal存進資料庫
        Renewal renewal = new Renewal();

        renewal.setMemberCourse(memberCourse);
        renewal.setRenewaldate(LocalDateTime.now());
        renewal.setAddedsessions(request.getAddedSessions());
        renewal.setAmount(request.getAmount());
        renewal.setPaymentmethod(request.getPaymentMethod());
        renewal.setNote(request.getNote());

        Renewal savedRenewal = renewalRepo.save(renewal);

        memberCourseService.addSessions(
                memberCourseId,
                request.getAddedSessions()
        );

        return savedRenewal;
    }
}