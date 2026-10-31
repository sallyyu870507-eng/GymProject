package tw.gymproject.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.member.MemberInBodyResponse;
import tw.gymproject.dto.member.MemberProfileResponse;
import tw.gymproject.dto.member.WeeklyAttendanceResponse;
import tw.gymproject.service.MemberDashboardService;
import tw.gymproject.service.MemberSessionService;

/**
 * 會員端 Dashboard（React 前端用）。
 * 放在 /api/member 底下：LoginInterceptor 對 /api 開頭會回 401 / 403，
 * 不會像一般網址那樣 redirect 到登入頁。
 * 就算 WebConfig 沒有註冊這個路徑，MemberSessionService 也會自己檢查登入與角色。
 */
@RestController
@RequestMapping("/api/member")
public class MemberDashboardController {

    private final MemberSessionService memberSessionService;
    private final MemberDashboardService memberDashboardService;

    public MemberDashboardController(
            MemberSessionService memberSessionService,
            MemberDashboardService memberDashboardService) {
        this.memberSessionService = memberSessionService;
        this.memberDashboardService = memberDashboardService;
    }

    /** 會員自己的基本資料 */
    @GetMapping("/profile")
    public MemberProfileResponse getProfile(HttpSession session) {
        Integer memberid = memberSessionService.getCurrentMemberId(session);
        return memberDashboardService.getProfile(memberid);
    }

    /** 最近幾週（預設 12 週）每週出席次數 */
    @GetMapping("/attendance")
    public List<WeeklyAttendanceResponse> getWeeklyAttendance(
            @RequestParam(defaultValue = "12") int weeks,
            HttpSession session) {
        Integer memberid = memberSessionService.getCurrentMemberId(session);
        return memberDashboardService.getWeeklyAttendance(memberid, weeks);
    }

    /** 所有 InBody 檢測紀錄，依日期由舊到新 */
    @GetMapping("/inbody")
    public List<MemberInBodyResponse> getInBodyRecords(HttpSession session) {
        Integer memberid = memberSessionService.getCurrentMemberId(session);
        return memberDashboardService.getInBodyRecords(memberid);
    }
}
