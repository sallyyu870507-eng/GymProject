package tw.gymproject.controller;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.dto.renewal.AttendanceSummaryResponse;
import tw.gymproject.dto.renewal.FollowUpCreateRequest;
import tw.gymproject.dto.renewal.FollowUpResponse;
import tw.gymproject.dto.renewal.FollowUpUpdateRequest;
import tw.gymproject.dto.renewal.FollowupPageResponse;
import tw.gymproject.dto.renewal.InBodyPageResponse;
import tw.gymproject.dto.renewal.RenewalOptionsResponse;
import tw.gymproject.dto.renewal.RenewalOverviewResponse;
import tw.gymproject.dto.renewal.RenewalWorkbenchResponse;
import tw.gymproject.dto.renewal.RenewalCreateRequest;

import tw.gymproject.exception.BusinessException;

import tw.gymproject.service.AttendanceSummaryService;
import tw.gymproject.service.CoachSessionService;
import tw.gymproject.service.FollowUpCreateService;
import tw.gymproject.service.FollowUpQueryService;
import tw.gymproject.service.FollowUpUpdateService;
import tw.gymproject.service.InBodyQueryService;
import tw.gymproject.service.RenewalOptionsService;
import tw.gymproject.service.RenewalOverviewService;
import tw.gymproject.service.RenewalWorkbenchService;
import tw.gymproject.service.SubmissionGuardService;
import tw.gymproject.service.RenewalCreateService;

import java.util.Collections;
import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/api/coach/renewal")
public class RenewalController {

    private static final Set<String> ALLOWED_QUERY_PARAMS =
            Set.of(
                    "scope",
                    "keyword",
                    "category",
                    "followupStatus",
                    "page",
                    "size"
            );

    private static final Set<String> PAGING_QUERY_PARAMS =
            Set.of("page", "size");

    private final CoachSessionService coachSessionService;
    private final RenewalWorkbenchService workbenchService;
    private final RenewalOverviewService renewalOverviewService;
    private final FollowUpQueryService followUpQueryService;
    private final FollowUpCreateService followUpCreateService;
    private final FollowUpUpdateService followUpUpdateService;
    private final AttendanceSummaryService attendanceSummaryService;
    private final InBodyQueryService inBodyQueryService;
    private final RenewalOptionsService renewalOptionsService;
    private final RenewalCreateService renewalCreateService;

    public RenewalController(
            CoachSessionService coachSessionService,
            RenewalWorkbenchService workbenchService,
            RenewalOverviewService renewalOverviewService,
            FollowUpQueryService followUpQueryService,
            FollowUpCreateService followUpCreateService,
            FollowUpUpdateService followUpUpdateService,
            AttendanceSummaryService attendanceSummaryService,
            InBodyQueryService inBodyQueryService,
            RenewalOptionsService renewalOptionsService,
            RenewalCreateService renewalCreateService
    ) {
        this.coachSessionService = coachSessionService;
        this.workbenchService = workbenchService;
        this.renewalOverviewService = renewalOverviewService;
        this.followUpQueryService = followUpQueryService;
        this.followUpCreateService = followUpCreateService;
        this.followUpUpdateService = followUpUpdateService;
        this.attendanceSummaryService = attendanceSummaryService;
        this.inBodyQueryService = inBodyQueryService;
        this.renewalOptionsService = renewalOptionsService;
        this.renewalCreateService = renewalCreateService;
    }

    // R1：工作台查詢
    @GetMapping
    public RenewalWorkbenchResponse getWorkbench(
            HttpServletRequest request,

            @RequestParam(name = "scope", required = false)
            String scope,

            @RequestParam(name = "keyword", required = false)
            String keyword,

            @RequestParam(name = "category", required = false)
            String category,

            @RequestParam(name = "followupStatus", required = false)
            String followupStatus,

            @RequestParam(name = "page", required = false)
            Integer page,

            @RequestParam(name = "size", required = false)
            Integer size
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        validateQueryParameters(request, ALLOWED_QUERY_PARAMS);

        return workbenchService.getWorkbench(
                coachId,
                scope == null ? "TRACKING" : scope,
                keyword == null ? "" : keyword,
                category == null ? "ALL" : category,
                followupStatus == null ? "ALL" : followupStatus,
                page == null ? 1 : page,
                size == null ? 10 : size
        );
    }

    // R2：方案詳情
    @GetMapping("/{memberCourseId}")
    public RenewalOverviewResponse getOverview(
            HttpServletRequest request,
            @PathVariable("memberCourseId") Integer memberCourseId
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        if (!request.getParameterMap().isEmpty()) {
            throw new BusinessException(
                    "方案詳情不接受查詢參數"
            );
        }

        return renewalOverviewService.getOverview(
                coachId,
                memberCourseId
        );
    }

    // F1：關懷紀錄列表
    @GetMapping("/{memberCourseId}/followups")
    public FollowupPageResponse getFollowups(
            HttpServletRequest request,

            @PathVariable("memberCourseId")
            Integer memberCourseId,

            @RequestParam(name = "page", required = false)
            Integer page,

            @RequestParam(name = "size", required = false)
            Integer size
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        validateQueryParameters(request, PAGING_QUERY_PARAMS);

        return followUpQueryService.getFollowups(
                coachId,
                memberCourseId,
                page == null ? 1 : page,
                size == null ? 10 : size
        );
    }

    // F2：新增關懷紀錄
    @PostMapping(
            value = "/{memberCourseId}/followups",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<String> createFollowup(
            HttpServletRequest request,

            @PathVariable("memberCourseId")
            Integer memberCourseId,

            @RequestBody
            FollowUpCreateRequest body
    ) {
        // 先確認已登入，且目前身分為教練。
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        if (!request.getParameterMap().isEmpty()) {
            throw new BusinessException(
                    "新增關懷不接受查詢參數"
            );
        }

        /*
         * CoachSessionService 已確認 Session 的 user。
         * 帳號 ID 從同一份登入資料取得，不接受 Body 指定。
         */
        LoginResultDTO user = (LoginResultDTO)
                request.getSession(false).getAttribute("user");

        Integer accountId = user.getAccountid();

        // 不允許多個同名提交編號 Header。
        List<String> keys = Collections.list(
                request.getHeaders("Idempotency-Key")
        );

        if (keys.size() > 1) {
            throw new BusinessException(
                    "Idempotency-Key 不可重複"
            );
        }

        String idempotencyKey =
                keys.isEmpty() ? null : keys.get(0);

        SubmissionGuardService.SubmissionResult result =
                followUpCreateService.createFollowUp(
                        coachId,
                        accountId,
                        memberCourseId,
                        idempotencyKey,
                        body
                );

        /*
         * Service 回傳已保存的 JSON 字串。
         * 明確指定 application/json，避免當成一般文字。
         * 不再進行一次 JSON 字串序列化。
         */
        return ResponseEntity
                .status(result.statusCode())
                .contentType(MediaType.APPLICATION_JSON)
                .body(result.responseJson());
    }

    // F3：讀取單筆關懷
    @GetMapping("/{memberCourseId}/followups/{followupId}")
    public FollowUpResponse getFollowup(
            HttpServletRequest request,

            @PathVariable("memberCourseId")
            Integer memberCourseId,

            @PathVariable("followupId")
            Integer followupId
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        if (!request.getParameterMap().isEmpty()) {
            throw new BusinessException(
                    "單筆關懷查詢不接受查詢參數"
            );
        }

        return followUpQueryService.getFollowup(
                coachId,
                memberCourseId,
                followupId
        );
    }

    // F4：修改原筆關懷
    @PutMapping("/{memberCourseId}/followups/{followupId}")
    public FollowUpResponse updateFollowup(
            HttpServletRequest request,

            @PathVariable("memberCourseId")
            Integer memberCourseId,

            @PathVariable("followupId")
            Integer followupId,

            @RequestBody
            FollowUpUpdateRequest body
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        if (!request.getParameterMap().isEmpty()) {
            throw new BusinessException(
                    "修改關懷不接受查詢參數"
            );
        }

        return followUpUpdateService.updateFollowup(
                coachId,
                memberCourseId,
                followupId,
                body
        );
    }

    // B1：本方案出席統計
    @GetMapping("/{memberCourseId}/attendance-summary")
    public AttendanceSummaryResponse getAttendanceSummary(
            HttpServletRequest request,
            @PathVariable("memberCourseId") Integer memberCourseId
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        if (!request.getParameterMap().isEmpty()) {
            throw new BusinessException(
                    "出席統計不接受查詢參數"
            );
        }

        return attendanceSummaryService.getSummary(
                coachId,
                memberCourseId
        );
    }

    // B2：本方案 InBody 摘要、趨勢與量測分頁
    @GetMapping("/{memberCourseId}/inbody")
    public InBodyPageResponse getInBody(
            HttpServletRequest request,

            @PathVariable("memberCourseId")
            Integer memberCourseId,

            @RequestParam(name = "page", required = false)
            Integer page,

            @RequestParam(name = "size", required = false)
            Integer size
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        validateQueryParameters(request, PAGING_QUERY_PARAMS);

        return inBodyQueryService.getInBody(
                coachId,
                memberCourseId,
                page == null ? 1 : page,
                size == null ? 5 : size
        );
    }

    // P1：續約表單初始化
    @GetMapping("/{memberCourseId}/renewal-options")
    public RenewalOptionsResponse getRenewalOptions(
            HttpServletRequest request,
            @PathVariable("memberCourseId") Integer memberCourseId
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        if (!request.getParameterMap().isEmpty()) {
            throw new BusinessException(
                    "續約初始化不接受查詢參數"
            );
        }

        return renewalOptionsService.getOptions(
                coachId,
                memberCourseId
        );
    }

    // P2：辦理續約，建立新方案與續約關聯。
    @PostMapping(
            value = "/{memberCourseId}/renewals",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<String> createRenewal(
            HttpServletRequest request,

            @PathVariable("memberCourseId")
            Integer memberCourseId,

            @RequestBody
            RenewalCreateRequest body
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        if (!request.getParameterMap().isEmpty()) {
            throw new BusinessException(
                    "辦理續約不接受查詢參數"
            );
        }

        // 帳號 ID 取自登入 Session，不接受 Body 指定。
        LoginResultDTO user = (LoginResultDTO)
                request.getSession(false).getAttribute("user");

        Integer accountId = user.getAccountid();

        List<String> keys = Collections.list(
                request.getHeaders("Idempotency-Key")
        );

        if (keys.size() > 1) {
            throw new BusinessException(
                    "Idempotency-Key 不可重複"
            );
        }

        String idempotencyKey =
                keys.isEmpty() ? null : keys.get(0);

        SubmissionGuardService.SubmissionResult result =
                renewalCreateService.createRenewal(
                        coachId,
                        accountId,
                        memberCourseId,
                        idempotencyKey,
                        body
                );

        return ResponseEntity
                .status(result.statusCode())
                .contentType(MediaType.APPLICATION_JSON)
                .body(result.responseJson());
    }

    // 共用查詢參數檢查
    private void validateQueryParameters(
            HttpServletRequest request,
            Set<String> allowedParams
    ) {
        request.getParameterMap().forEach((name, values) -> {
            if (!allowedParams.contains(name)) {
                throw new BusinessException(
                        "不支援的查詢參數：" + name
                );
            }

            if (values.length != 1) {
                throw new BusinessException(
                        "查詢參數不可重複：" + name
                );
            }

            if (("page".equals(name) || "size".equals(name))
                    && values[0].isBlank()) {
                throw new BusinessException(
                        name + " 不可為空白"
                );
            }
        });
    }
}