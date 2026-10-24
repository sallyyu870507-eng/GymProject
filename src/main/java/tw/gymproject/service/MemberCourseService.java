package tw.gymproject.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tw.gymproject.entity.Membercourse;
import tw.gymproject.exception.ConflictException;
import tw.gymproject.exception.ResourceNotFoundException;
import tw.gymproject.repository.MemberCourseRepo;

@Service
public class MemberCourseService {

    private final MemberCourseRepo memberCourseRepo;

    public MemberCourseService(
            MemberCourseRepo memberCourseRepo
    ) {
        this.memberCourseRepo = memberCourseRepo;
    }

    public Membercourse getById(Integer memberCourseId) {
        return memberCourseRepo
                .findById(memberCourseId)
                .orElseThrow(
                        () -> new ResourceNotFoundException(
                                "找不到 Membercourse：" + memberCourseId
                        )
                );
    }

    // 扣 1 堂，並同步方案狀態。
    @Transactional
    public void decreaseSession(Integer memberCourseId) {
        Membercourse memberCourse = getById(memberCourseId);

        validateSessions(memberCourse);

        int remaining = memberCourse.getRemainingsessions();

        if (remaining == 0) {
            throw new ConflictException(
                    "剩餘堂數不足，無法扣堂"
            );
        }

        int updatedRemaining = remaining - 1;

        memberCourse.setRemainingsessions(updatedRemaining);

        memberCourse.setStatus(
                updatedRemaining == 0 ? "usedup" : "active"
        );
    }

    // 補回 1 堂，並同步方案狀態。
    @Transactional
    public void increaseSession(Integer memberCourseId) {
        Membercourse memberCourse = getById(memberCourseId);

        validateSessions(memberCourse);

        int remaining = memberCourse.getRemainingsessions();
        int total = memberCourse.getTotalsessions();

        if (remaining >= total) {
            throw new ConflictException(
                    "補回堂數後不可超過總堂數"
            );
        }

        memberCourse.setRemainingsessions(remaining + 1);
        memberCourse.setStatus("active");
    }

    private void validateSessions(Membercourse memberCourse) {
        Integer total = memberCourse.getTotalsessions();
        Integer remaining = memberCourse.getRemainingsessions();

        if (total == null
                || total <= 0
                || remaining == null
                || remaining < 0
                || remaining > total) {
            throw new ConflictException(
                    "方案堂數資料異常，請先確認資料"
            );
        }
    }
}