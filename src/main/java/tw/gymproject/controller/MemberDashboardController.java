package tw.gymproject.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.member.AvatarResponse;
import tw.gymproject.dto.member.BookingStatsResponse;
import tw.gymproject.dto.member.MemberCourseResponse;
import tw.gymproject.dto.member.MemberInBodyResponse;
import tw.gymproject.dto.member.NextClassResponse;
import tw.gymproject.dto.member.MemberProfileResponse;
import tw.gymproject.dto.member.WeeklyAttendanceResponse;
import tw.gymproject.service.AvatarStorageService;
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
    private final AvatarStorageService avatarStorage;

    public MemberDashboardController(
            MemberSessionService memberSessionService,
            MemberDashboardService memberDashboardService,
            AvatarStorageService avatarStorage) {
        this.memberSessionService = memberSessionService;
        this.memberDashboardService = memberDashboardService;
        this.avatarStorage = avatarStorage;
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
            @RequestParam(name = "weeks", defaultValue = "12") int weeks,
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

    /** 下一堂還沒上的預約課；沒有的話回 204 No Content */
    @GetMapping("/next-class")
    public ResponseEntity<NextClassResponse> getNextClass(HttpSession session) {
        Integer memberid = memberSessionService.getCurrentMemberId(session);
        NextClassResponse next = memberDashboardService.getNextClass(memberid);
        return next == null ? ResponseEntity.noContent().build() : ResponseEntity.ok(next);
    }

    /** 使用中的課程方案與剩餘堂數 */
    @GetMapping("/courses")
    public List<MemberCourseResponse> getCourses(HttpSession session) {
        Integer memberid = memberSessionService.getCurrentMemberId(session);
        return memberDashboardService.getCourses(memberid);
    }

    /** 已完成／已取消／即將上課的預約次數 */
    @GetMapping("/booking-stats")
    public BookingStatsResponse getBookingStats(HttpSession session) {
        Integer memberid = memberSessionService.getCurrentMemberId(session);
        return memberDashboardService.getBookingStats(memberid);
    }

    /**
     * 上傳會員照片（multipart/form-data，欄位名稱 file，JPG／PNG／WebP，1 MB 以內）。
     * 存好後更新 member.avatarurl，並刪掉舊照片。
     */
    @PostMapping("/avatar")
    public AvatarResponse uploadAvatar(@RequestParam("file") MultipartFile file, HttpSession session) {
        Integer memberid = memberSessionService.getCurrentMemberId(session);
        String url = avatarStorage.save(memberid, file);
        String old = memberDashboardService.updateAvatarUrl(memberid, url);
        avatarStorage.deleteIfOwned(old);
        return new AvatarResponse(url);
    }
}
