package tw.gymproject.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.gymproject.entity.MemberCourse;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ResourceNotFoundException;
import tw.gymproject.repository.MemberCourseRepo;

@Service
public class MemberCourseService {


    private final MemberCourseRepo memberCourseRepo;

    public MemberCourseService(MemberCourseRepo memberCourseRepo) {
        this.memberCourseRepo = memberCourseRepo;
    }

    //getById()→ 找 MemberCourse
    public MemberCourse getById(
            Integer memberCourseId
    ) {

        return memberCourseRepo
                .findById(memberCourseId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "找不到 MemberCourse：" + memberCourseId
                        )
                );
    }

    //decreaseSession()→ 剩餘堂數 -1
    @Transactional
    public void decreaseSession(Integer memberCourseId) {

        MemberCourse memberCourse = getById(memberCourseId);

        Integer remaining = memberCourse.getRemainingsessions();

        if (remaining <= 0) {
            throw new BusinessException(
                    "剩餘堂數不足，無法扣堂"
            );
        }

        memberCourse.setRemainingsessions(remaining - 1);
    }

    //increaseSession()→ 剩餘堂數 +1
    @Transactional
    public void increaseSession(Integer memberCourseId) {

        MemberCourse memberCourse = getById(memberCourseId);

        Integer remaining = memberCourse.getRemainingsessions();

        memberCourse.setRemainingsessions(remaining + 1);
    }

    /*
    addSessions() 是正式續約
    totalsessions     + addedSessions
    remainingsessions + addedSessions
     */
    @Transactional
    public void addSessions(Integer memberCourseId, Integer addedSessions) {

        MemberCourse memberCourse = getById(memberCourseId);

        if (addedSessions == null|| addedSessions <= 0) {
            throw new BusinessException("新增堂數必須大於 0");
        }

        Integer total = memberCourse.getTotalsessions();
        Integer remaining = memberCourse.getRemainingsessions();

        memberCourse.setTotalsessions(total + addedSessions);
        memberCourse.setRemainingsessions(remaining + addedSessions);
    }
}