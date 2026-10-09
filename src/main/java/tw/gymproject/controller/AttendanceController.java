package tw.gymproject.controller;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import tw.gymproject.dto.attendance.AttendanceDetailResponse;
import tw.gymproject.dto.attendance.AttendanceListResponse;
import tw.gymproject.dto.attendance.AttendanceUpdateRequest;
import tw.gymproject.service.AttendanceService;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/attendance")
public class AttendanceController {
    private final AttendanceService attendanceService;

    public AttendanceController(
            AttendanceService attendanceService
    ) {
        this.attendanceService =
                attendanceService;
    }

    // 開發階段暫時固定 coachId = 1
    // 未來登入完成：
    // 改成從登入身分取得
    private Integer getCurrentCoachId() {
        return 1;
    }



    // API 1
    // GET /api/attendance?date=2026-09-27
    // 指定日期：統計 + 今日課程卡片
    @GetMapping
    public ResponseEntity<AttendanceListResponse>
    getAttendanceList(
            @RequestParam("date")
            @DateTimeFormat(
                    iso = DateTimeFormat.ISO.DATE
            )
            LocalDate date
    ) {
        Integer currentCoachId =
                getCurrentCoachId();

        AttendanceListResponse response =
                attendanceService
                        .getAttendanceList(
                                date,
                                currentCoachId
                        );
        return ResponseEntity.ok(
                response
        );
    }



    // API 2
    // GET /api/attendance/{bookingId}
    // 點擊會員卡片後：取得完整 Detail


    @GetMapping("/{bookingId}")
    public ResponseEntity<AttendanceDetailResponse>
    getAttendanceDetail(

            @PathVariable("bookingId")
            Integer bookingId

    ) {
        Integer currentCoachId =
                getCurrentCoachId();

        AttendanceDetailResponse response =
                attendanceService
                        .getAttendanceDetail(
                                bookingId,
                                currentCoachId
                        );
        return ResponseEntity.ok(
                response
        );
    }



    // API 3
    // PUT /api/attendance/{bookingId}
    // 更新：
    // PRESENT / LEAVE / ABSENT
    // workoutFocus
    // note
    // InBody

    @PutMapping("/{bookingId}")
    public ResponseEntity<AttendanceDetailResponse>
    updateAttendance(

            @PathVariable("bookingId")
            Integer bookingId,
            @RequestBody
            AttendanceUpdateRequest request
    ) {
        Integer currentCoachId =
                getCurrentCoachId();
        AttendanceDetailResponse response =
                attendanceService
                        .updateAttendance(
                                bookingId,
                                currentCoachId,
                                request
                        );
        return ResponseEntity.ok(
                response
        );
    }
}