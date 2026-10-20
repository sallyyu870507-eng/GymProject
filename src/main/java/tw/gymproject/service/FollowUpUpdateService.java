package tw.gymproject.service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tw.gymproject.dto.renewal.FollowUpResponse;
import tw.gymproject.dto.renewal.FollowUpUpdateRequest;
import tw.gymproject.entity.FollowUp;
import tw.gymproject.entity.MemberCourse;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ConflictException;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.exception.ResourceNotFoundException;
import tw.gymproject.repository.FollowUpRepo;
import tw.gymproject.repository.MemberCourseRepo;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.Objects;
import java.util.Set;


//更新原紀錄的聯繫時間、方式、結果、備註，保留原 ID、方案與記錄教練，不改堂數。
@Service
public class FollowUpUpdateService {

    private static final ZoneId TAIPEI =
            ZoneId.of("Asia/Taipei");

    private static final Set<String> CONTACT_METHODS =
            Set.of(
                    "PHONE",
                    "MESSAGE",
                    "IN_PERSON",
                    "OTHER"
            );

    private static final Set<String> STATUSES =
            Set.of(
                    "NO_RESPONSE",
                    "CONSIDERING",
                    "AGREED",
                    "DECLINED"
            );

    private final MemberCourseRepo memberCourseRepo;
    private final FollowUpRepo followUpRepo;
    private final EntityManager entityManager;

    public FollowUpUpdateService(
            MemberCourseRepo memberCourseRepo,
            FollowUpRepo followUpRepo,
            EntityManager entityManager
    ) {
        this.memberCourseRepo = memberCourseRepo;
        this.followUpRepo = followUpRepo;
        this.entityManager = entityManager;
    }

    @Transactional
    public FollowUpResponse updateFollowup(
            Integer coachId,
            Integer memberCourseId,
            Integer followupId,
            FollowUpUpdateRequest request
    ) {
        // 同一次請求固定使用這個台北時間
        LocalDateTime now = LocalDateTime.now(TAIPEI);

        // 1. 檢查方案與權限
        requireAuthorizedPlan(coachId, memberCourseId);

        if (followupId == null || followupId <= 0) {
            throw new BusinessException(
                    "followupId 必須為正整數"
            );
        }

        // 2. 紀錄必須屬於網址指定的方案
        FollowUp followUp = followUpRepo
                .findDetailByIdAndMemberCourseId(
                        followupId,
                        memberCourseId
                )
                .orElseThrow(
                        () -> new ResourceNotFoundException(
                                "找不到此方案的指定關懷紀錄"
                        )
                );

        // 鎖定並重新讀取目前資料，
        // 讓時間比對與更新在同一筆交易內完成
        entityManager.refresh(
                followUp,
                LockModeType.PESSIMISTIC_WRITE
        );

        // 重新確認鎖定後的方案關聯
        if (!Objects.equals(
                followUp.getMemberCourse().getMembercourseid(),
                memberCourseId
        )) {
            throw new ResourceNotFoundException(
                    "找不到此方案的指定關懷紀錄"
            );
        }

        // 3. 驗證修改內容
        if (request == null) {
            throw new BusinessException(
                    "請提供修改內容"
            );
        }

        if (request.getContactTimeChanged() == null) {
            throw new BusinessException(
                    "contactTimeChanged 為必填"
            );
        }

        String contactMethod = request.getContactMethod();

        if (contactMethod == null
                || !CONTACT_METHODS.contains(contactMethod)) {
            throw new BusinessException(
                    "contactMethod 必須為 PHONE、MESSAGE、IN_PERSON 或 OTHER"
            );
        }

        String status = request.getStatus();

        if (status == null || !STATUSES.contains(status)) {
            throw new BusinessException(
                    "status 必須為 NO_RESPONSE、CONSIDERING、AGREED 或 DECLINED"
            );
        }

        LocalDateTime submittedTime =
                parseCreatedDate(request.getCreatedDate());

        // 即使不修改時間，也不能保留未來的聯繫時間
        if (submittedTime.isAfter(now)) {
            throw new BusinessException(
                    "聯繫時間不能晚於現在"
            );
        }

        String note = normalizeNote(request.getNote());

        // 4. 決定是否更新聯繫時間
        if (request.getContactTimeChanged()) {
            // 明確改時間：先驗證，再歸零秒與小數秒
            followUp.setCreatedate(
                    submittedTime.truncatedTo(ChronoUnit.MINUTES)
            );
        } else {
            LocalDateTime originalTime =
                    followUp.getCreatedate();

            if (originalTime == null) {
                throw new BusinessException(
                        "原聯繫時間為空，請補填時間並將 contactTimeChanged 設為 true"
                );
            }

            // 包含秒與小數秒，必須完整一致
            if (!originalTime.equals(submittedTime)) {
                throw new ConflictException(
                        "聯繫時間與目前資料不一致，請重新載入後再修改"
                );
            }

            // false 時不呼叫 setCreatedate，保留原值
        }

        // 5. 只修改允許的欄位
        followUp.setContactmethod(contactMethod);
        followUp.setStatus(status);
        followUp.setNote(note);

        // followUp 是交易內受管理的 Entity，
        // Hibernate 會在 flush／提交時更新原紀錄
        entityManager.flush();

        // SQL Server DATETIME 可能調整時間精度，
        // 重新讀取以回傳實際保存的值
        entityManager.refresh(followUp);

        return toResponse(followUp);
    }

    private void requireAuthorizedPlan(
            Integer coachId,
            Integer memberCourseId
    ) {
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

        MemberCourse plan = memberCourseRepo
                .findOverviewById(memberCourseId)
                .orElseThrow(
                        () -> new ResourceNotFoundException(
                                "找不到指定方案"
                        )
                );

        if (!Objects.equals(
                plan.getCoach().getCoachid(),
                coachId
        )) {
            throw new ForbiddenException(
                    "無權修改其他教練方案的關懷紀錄"
            );
        }

        // 停用會員仍允許更正關懷歷史
    }

    private LocalDateTime parseCreatedDate(String value) {
        if (value == null || value.isBlank()) {
            throw new BusinessException(
                    "createdDate 為必填"
            );
        }

        // 要求完整當地日期時間：
        // yyyy-MM-ddTHH:mm:ss，可附 1～9 位小數秒
        // 不接受只有日期、時區 Z 或 offset
        if (!value.matches(
                "\\d{4}-\\d{2}-\\d{2}T"
                        + "\\d{2}:\\d{2}:\\d{2}"
                        + "(?:\\.\\d{1,9})?"
        )) {
            throw new BusinessException(
                    "createdDate 必須為不含時區的完整日期時間，例如 2026-10-15T10:00:00"
            );
        }

        try {
            LocalDateTime parsed = LocalDateTime.parse(
                    value,
                    DateTimeFormatter.ISO_LOCAL_DATE_TIME
            );

            // SQL Server DATETIME 的日期範圍
            if (parsed.getYear() < 1753
                    || parsed.getYear() > 9999) {
                throw new BusinessException(
                        "createdDate 超出資料庫可儲存的日期範圍"
                );
            }

            return parsed;
        } catch (DateTimeParseException ex) {
            throw new BusinessException(
                    "createdDate 日期時間不合法"
            );
        }
    }

    private String normalizeNote(String value) {
        if (value == null) {
            return null;
        }

        String note = value.strip();

        if (note.isEmpty()) {
            return null;
        }

        // String.length() 計算 UTF-16 單位
        if (note.length() > 500) {
            throw new BusinessException(
                    "note 不可超過 500 個 UTF-16 單位"
            );
        }

        return note;
    }

    private FollowUpResponse toResponse(FollowUp followUp) {
        FollowUpResponse response =
                new FollowUpResponse();

        response.setFollowupId(
                followUp.getFollowupid()
        );

        response.setMemberCourseId(
                followUp.getMemberCourse().getMembercourseid()
        );

        response.setCreatedDate(
                followUp.getCreatedate()
        );

        response.setCoachId(
                followUp.getCoach().getCoachid()
        );

        response.setCoachName(
                followUp.getCoach().getName()
        );

        response.setContactMethod(
                followUp.getContactmethod()
        );

        response.setStatus(
                followUp.getStatus()
        );

        response.setNote(
                followUp.getNote()
        );

        return response;
    }
}