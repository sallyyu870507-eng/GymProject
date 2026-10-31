package tw.gymproject.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import tw.gymproject.dto.renewal.AttendanceSummaryResponse;
import tw.gymproject.entity.Membercourse;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.exception.ResourceNotFoundException;
import tw.gymproject.repository.AttendanceRepo;
import tw.gymproject.repository.MemberCourseRepo;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Objects;


//用途:確認方案權限，以同一個台北時間統計出席、請假、缺席次數。
@Service
public class AttendanceSummaryService {

    private static final ZoneId TAIPEI =
            ZoneId.of("Asia/Taipei");

    private final MemberCourseRepo memberCourseRepo;
    private final AttendanceRepo attendanceRepo;

    public AttendanceSummaryService(
            MemberCourseRepo memberCourseRepo,
            AttendanceRepo attendanceRepo
    ) {
        this.memberCourseRepo = memberCourseRepo;
        this.attendanceRepo = attendanceRepo;
    }

    @Transactional(
            readOnly = true,
            isolation = Isolation.SERIALIZABLE
    )
    public AttendanceSummaryResponse getSummary(
            Integer coachId,
            Integer memberCourseId
    ) {
        // 同一次請求固定使用同一個台北時間
        LocalDateTime asOfDateTime =
                LocalDateTime.now(TAIPEI);

        // 1. 檢查 ID
        if (coachId == null || coachId <= 0) {
            throw new IllegalStateException(
                    "登入教練 ID 不完整"
            );
        }

        if (memberCourseId == null || memberCourseId <= 0) {
            throw new BusinessException(
                    "memberCourseId 必須為正整數"
            );
        }

        // 2. 查方案
        Membercourse plan = memberCourseRepo
                .findOverviewById(memberCourseId)
                .orElseThrow(
                        () -> new ResourceNotFoundException(
                                "找不到指定方案"
                        )
                );

        // 3. 確認方案屬於目前登入教練
        if (!Objects.equals(
                plan.getCoach().getCoachid(),
                coachId
        )) {
            throw new ForbiddenException(
                    "無權查看其他教練方案的出席統計"
            );
        }

        // 停用會員仍可查看歷史統計

        // 4. 查本方案已開始課程的統計
        AttendanceRepo.AttendanceSummaryCounts counts =
                attendanceRepo.findAttendanceSummary(
                        memberCourseId,
                        asOfDateTime.toLocalDate(),
                        asOfDateTime.toLocalTime()
                );

        // 聚合查詢應回傳一筆完整統計；
        // 異常不能當成「沒有紀錄」而回零
        if (counts == null
                || counts.getPresentCount() == null
                || counts.getLeaveCount() == null
                || counts.getAbsentCount() == null) {
            throw new IllegalStateException(
                    "出席統計查詢結果不完整"
            );
        }

        // 5. 組成回傳 DTO
        AttendanceSummaryResponse response =
                new AttendanceSummaryResponse();

        response.setMemberCourseId(memberCourseId);
        response.setAsOfDateTime(asOfDateTime);
        response.setPresentCount(counts.getPresentCount());
        response.setLeaveCount(counts.getLeaveCount());
        response.setAbsentCount(counts.getAbsentCount());

        return response;
    }
}