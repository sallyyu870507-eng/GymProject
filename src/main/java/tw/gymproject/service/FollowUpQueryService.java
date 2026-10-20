package tw.gymproject.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import tw.gymproject.dto.renewal.FollowUpResponse;
import tw.gymproject.dto.renewal.FollowupPageResponse;
import tw.gymproject.entity.FollowUp;
import tw.gymproject.entity.MemberCourse;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.exception.ResourceNotFoundException;
import tw.gymproject.repository.FollowUpRepo;
import tw.gymproject.repository.MemberCourseRepo;

import java.util.Objects;

@Service
public class FollowUpQueryService {

    private static final int PAGE_SIZE = 10;

    private final MemberCourseRepo memberCourseRepo;
    private final FollowUpRepo followUpRepo;

    public FollowUpQueryService(
            MemberCourseRepo memberCourseRepo,
            FollowUpRepo followUpRepo
    ) {
        this.memberCourseRepo = memberCourseRepo;
        this.followUpRepo = followUpRepo;
    }

    // F1：關懷紀錄列表
    @Transactional(
            readOnly = true,
            isolation = Isolation.SERIALIZABLE
    )
    public FollowupPageResponse getFollowups(
            Integer coachId,
            Integer memberCourseId,
            Integer page,
            Integer size
    ) {
        if (page == null || page < 1) {
            throw new BusinessException(
                    "page 必須為大於或等於 1 的整數"
            );
        }

        if (size == null || size != PAGE_SIZE) {
            throw new BusinessException(
                    "size 固定為 10"
            );
        }

        requireAuthorizedPlan(coachId, memberCourseId);

        Page<FollowUp> firstPage =
                followUpRepo.findPageByMemberCourseId(
                        memberCourseId,
                        PageRequest.of(0, PAGE_SIZE)
                );

        long totalElements = firstPage.getTotalElements();
        int totalPages = firstPage.getTotalPages();

        int actualPage = totalPages == 0
                ? 1
                : Math.min(page, totalPages);

        Page<FollowUp> selectedPage;

        if (actualPage == 1) {
            selectedPage = firstPage;
        } else {
            selectedPage =
                    followUpRepo.findPageByMemberCourseId(
                            memberCourseId,
                            PageRequest.of(
                                    actualPage - 1,
                                    PAGE_SIZE
                            )
                    );
        }

        FollowupPageResponse response =
                new FollowupPageResponse();

        response.setMemberCourseId(memberCourseId);

        response.setItems(
                selectedPage.getContent()
                        .stream()
                        .map(this::toResponse)
                        .toList()
        );

        response.setLatestFollowup(
                firstPage.hasContent()
                        ? toResponse(firstPage.getContent().get(0))
                        : null
        );

        FollowupPageResponse.PageInfo pageInfo =
                new FollowupPageResponse.PageInfo();

        pageInfo.setNumber(actualPage);
        pageInfo.setSize(PAGE_SIZE);
        pageInfo.setTotalElements(totalElements);
        pageInfo.setTotalPages(totalPages);
        pageInfo.setHasPrevious(actualPage > 1);
        pageInfo.setHasNext(actualPage < totalPages);

        response.setPage(pageInfo);

        return response;
    }

    // F3：讀取單筆關懷紀錄
    @Transactional(readOnly = true)
    public FollowUpResponse getFollowup(
            Integer coachId,
            Integer memberCourseId,
            Integer followupId
    ) {
        // 先驗證方案存在與教練權限
        requireAuthorizedPlan(coachId, memberCourseId);

        if (followupId == null || followupId <= 0) {
            throw new BusinessException(
                    "followupId 必須為正整數"
            );
        }

        // 紀錄必須同時符合 ID 與所屬方案
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

        return toResponse(followUp);
    }

    // 共用：確認方案存在且屬於登入教練
    private MemberCourse requireAuthorizedPlan(
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
                    "無權查看其他教練的方案"
            );
        }

        // 停用會員仍可查歷史
        return plan;
    }

    // Entity 轉成回傳 DTO
    private FollowUpResponse toResponse(FollowUp followUp) {
        FollowUpResponse response =
                new FollowUpResponse();

        response.setFollowupId(
                followUp.getFollowupid()
        );

        response.setMemberCourseId(
                followUp.getMemberCourse()
                        .getMembercourseid()
        );

        // 保留原始時間，包括秒與小數秒
        response.setCreatedDate(
                followUp.getCreatedate()
        );

        response.setCoachId(
                followUp.getCoach().getCoachid()
        );

        response.setCoachName(
                followUp.getCoach().getName()
        );

        // 保留歷史原值，不修改未知代碼或 null
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