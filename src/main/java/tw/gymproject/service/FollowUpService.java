package tw.gymproject.service;
/*
createFollowUp()
→ 新增一筆追蹤紀錄

getHistory()
→ 查某個 MemberCourse 的所有追蹤歷史
 */

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.gymproject.entity.Coach;
import tw.gymproject.entity.FollowUp;
import tw.gymproject.entity.MemberCourse;
import tw.gymproject.repository.FollowUpRepo;
import tw.gymproject.dto.FollowUpRequest;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class FollowUpService {

    private final FollowUpRepo followUpRepo;
    private final MemberCourseService memberCourseService;

    public FollowUpService(
            FollowUpRepo followUpRepo,
            MemberCourseService memberCourseService
    ) {
        this.followUpRepo = followUpRepo;
        this.memberCourseService = memberCourseService;
    }

    @Transactional
    public FollowUp createFollowUp(
            Integer memberCourseId,
            FollowUpRequest request
    ) {

        MemberCourse memberCourse =
                memberCourseService.getById(memberCourseId);

        Coach coach = memberCourse.getCoach();

        FollowUp followUp = new FollowUp();

        followUp.setMemberCourse(memberCourse);
        followUp.setCoach(coach);
        followUp.setStatus(request.getStatus());
        followUp.setContactmethod(request.getContactMethod());
        followUp.setNote(request.getNote());
        followUp.setCreatedate(LocalDateTime.now());

        return followUpRepo.save(followUp);
    }
}