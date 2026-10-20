package tw.gymproject.controller;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import tw.gymproject.dto.attendance.AttendanceDetailResponse;
import tw.gymproject.dto.attendance.AttendanceListResponse;
import tw.gymproject.dto.attendance.AttendanceUpdateRequest;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.service.AttendanceService;
import tw.gymproject.service.CoachSessionService;

import java.time.LocalDate;
import java.util.Set;

@RestController
@RequestMapping("/api/attendance")
public class AttendanceController {

    private static final Set<String> LIST_QUERY_PARAMS =
            Set.of("date");

    private static final Set<String> NO_QUERY_PARAMS =
            Set.of();

    private final AttendanceService attendanceService;
    private final CoachSessionService coachSessionService;

    public AttendanceController(
            AttendanceService attendanceService,
            CoachSessionService coachSessionService
    ) {
        this.attendanceService = attendanceService;
        this.coachSessionService = coachSessionService;
    }

    // A1：指定日期的出席工作台
    @GetMapping
    public ResponseEntity<AttendanceListResponse>
    getAttendanceList(
            @RequestParam("date")
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date,

            HttpServletRequest request
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        validateQueryParameters(request, LIST_QUERY_PARAMS);

        return ResponseEntity.ok(
                attendanceService.getAttendanceList(
                        date,
                        coachId
                )
        );
    }

    // A2：單一預約的出席詳情
    @GetMapping("/{bookingId}")
    public ResponseEntity<AttendanceDetailResponse>
    getAttendanceDetail(
            @PathVariable("bookingId")
            Integer bookingId,

            HttpServletRequest request
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        validateQueryParameters(request, NO_QUERY_PARAMS);

        return ResponseEntity.ok(
                attendanceService.getAttendanceDetail(
                        bookingId,
                        coachId
                )
        );
    }

    // A3：更新出席、堂數與 InBody
    @PutMapping("/{bookingId}")
    public ResponseEntity<AttendanceDetailResponse>
    updateAttendance(
            @PathVariable("bookingId")
            Integer bookingId,

            @RequestBody
            AttendanceUpdateRequest body,

            HttpServletRequest request
    ) {
        Integer coachId = coachSessionService.getCurrentCoachId(
                request.getSession(false)
        );

        validateQueryParameters(request, NO_QUERY_PARAMS);

        return ResponseEntity.ok(
                attendanceService.updateAttendance(
                        bookingId,
                        coachId,
                        body
                )
        );
    }

    // 只檢查 Attendance API，不影響其他 Controller。
    private void validateQueryParameters(
            HttpServletRequest request,
            Set<String> allowedNames
    ) {
        request.getParameterMap().forEach((name, values) -> {
            if (!allowedNames.contains(name)) {
                throw new BusinessException(
                        "不支援的查詢參數：" + name
                );
            }

            if (values.length != 1) {
                throw new BusinessException(
                        "查詢參數不可重複：" + name
                );
            }

            if (values[0].isBlank()) {
                throw new BusinessException(
                        name + " 不可為空白"
                );
            }
        });
    }
}