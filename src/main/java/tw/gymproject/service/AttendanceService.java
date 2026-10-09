package tw.gymproject.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import tw.gymproject.dto.attendance.AttendanceCardResponse;
import tw.gymproject.dto.attendance.AttendanceListResponse;
import tw.gymproject.dto.attendance.AttendanceSummaryResponse;
import tw.gymproject.dto.attendance.AttendanceUpdateRequest;
import tw.gymproject.dto.inbody.InBodyRequest;
import tw.gymproject.dto.attendance.AttendanceDetailResponse;
import tw.gymproject.dto.attendance.AttendanceHistoryResponse;
import tw.gymproject.dto.inbody.InBodyResponse;

import tw.gymproject.entity.Attendance;
import tw.gymproject.entity.Booking;
import tw.gymproject.entity.InBodyRecord;
import tw.gymproject.entity.MemberCourse;

import tw.gymproject.repository.AttendanceRepo;
import tw.gymproject.repository.BookingRepo;
import tw.gymproject.repository.InBodyRecordRepo;

import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ResourceNotFoundException;
import tw.gymproject.exception.ForbiddenException;


@Service
public class AttendanceService {

    private final AttendanceRepo attendanceRepo;
    private final BookingRepo bookingRepo;
    private final InBodyRecordRepo inBodyRecordRepo;
    private final MemberCourseService memberCourseService;

    public AttendanceService(
            AttendanceRepo attendanceRepo,
            BookingRepo bookingRepo,
            InBodyRecordRepo inBodyRecordRepo,
            MemberCourseService memberCourseService
    ) {
        this.attendanceRepo = attendanceRepo;
        this.bookingRepo = bookingRepo;
        this.inBodyRecordRepo = inBodyRecordRepo;
        this.memberCourseService = memberCourseService;
    }

    // =========================================================
    // 1. 更新 Attendance
    //PUT /api/attendance/{bookingId}
    // =========================================================
    @Transactional
    public AttendanceDetailResponse updateAttendance(
            Integer bookingId,
            Integer coachId,
            AttendanceUpdateRequest request
    ) {

        // 1. 找 Booking
        Booking booking = bookingRepo.findById(bookingId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "找不到 Booking：" + bookingId
                        )
                );

        // 2. 找 MemberCourse
        MemberCourse memberCourse =
                booking.getMembercourse();

        // 3. 權限檢查->只能操作自己負責的 MemberCourse
        if (!memberCourse.getCoach()
                .getCoachid()
                .equals(coachId)) {

            throw new ForbiddenException(
                    "無權限修改其他教練的學員"
            );
        }


        // 4. 已取消 Booking 不允許更新出席
        /*
         * 目前先使用 CANCELLED。
         * 之後仍要確認 bookingstatus 的正式值。
         */
        if ("CANCELLED".equalsIgnoreCase(
                booking.getBookingstatus()
        )) {
            throw new BusinessException(
                    "已取消的預約不能更新出席"
            );
        }

        // 5. 找 Attendance 還不存在：建立新的，初始狀態 PENDING
        Attendance attendance = attendanceRepo
                .findByBooking_Bookingid(bookingId)
                .orElseGet(() -> {

                    Attendance newAttendance =
                            new Attendance();

                    newAttendance.setBooking(booking);

                    newAttendance.setAttendancestatus(
                            "PENDING"
                    );

                    return newAttendance;
                });

        // 6. 舊狀態 / 新狀態
        String oldStatus =
                attendance.getAttendancestatus();

        String newStatus =
                request.getStatus();

        // 7. 驗證新狀態
        validateAttendanceStatus(newStatus);

        // 8. MemberCourse ID
        Integer memberCourseId =
                memberCourse.getMembercourseid();

        // 9. 堂數調整
        handleSessionChange(
                oldStatus,
                newStatus,
                memberCourseId
        );

        // 10. 更新 Attendance
        attendance.setAttendancestatus(
                newStatus
        );

        attendance.setWorkoutfocus(
                request.getWorkoutFocus()
        );

        attendance.setNote(
                request.getNote()
        );

        attendance.setUpdatetime(
                LocalDateTime.now()
        );

        // 11. checkintime
        if ("PRESENT".equals(newStatus)) {
            if (!"PRESENT".equals(oldStatus)) {
                attendance.setCheckintime(
                        LocalDateTime.now()
                );
            }
        } else {
            attendance.setCheckintime(null);
        }

        // 12. 儲存 Attendance
        Attendance savedAttendance =
                attendanceRepo.save(attendance);


        // 13. 處理 InBody
        handleInBody(
                savedAttendance,
                memberCourse,
                newStatus,
                request.getInBody()
        );

        // 14. 回傳更新後完整 Detail ->不再直接把 Entity 回給前端
        return getAttendanceDetail(
                bookingId,
                coachId
        );
    }


    // =========================================================
    // 2. 驗證 Attendance status
    // =========================================================

    private void validateAttendanceStatus(
            String status
    ) {

        /*
         * null 也會進入這個判斷，
         * 因此不需要另外先判斷 null。
         */
        if (!"PRESENT".equals(status)
                && !"LEAVE".equals(status)
                && !"ABSENT".equals(status)) {

            throw new BusinessException(
                    "出席狀態只允許 PRESENT、LEAVE、ABSENT"
            );
        }
    }


    // =========================================================
    // 3. 處理堂數變化
    // =========================================================

    private void handleSessionChange(
            String oldStatus,
            String newStatus,
            Integer memberCourseId
    ) {

        boolean oldIsPresent =
                "PRESENT".equals(oldStatus);

        boolean newIsPresent =
                "PRESENT".equals(newStatus);


        /*
         * 原本不是 PRESENT
         * ↓
         * 現在變 PRESENT
         *
         * PENDING → PRESENT
         * LEAVE   → PRESENT
         * ABSENT  → PRESENT
         *
         * 扣 1 堂
         */
        if (!oldIsPresent && newIsPresent) {

            memberCourseService.decreaseSession(
                    memberCourseId
            );
        }


        /*
         * 原本 PRESENT
         * ↓
         * 現在不是 PRESENT
         *
         * PRESENT → LEAVE
         * PRESENT → ABSENT
         *
         * 補回 1 堂
         */
        if (oldIsPresent && !newIsPresent) {
            memberCourseService.increaseSession(
                    memberCourseId
            );
        }


        /*
         * 其他：
         * PRESENT → PRESENT
         * LEAVE → LEAVE
         * ABSENT → ABSENT
         * LEAVE → ABSENT
         * ABSENT → LEAVE
         * 堂數都不變
         */
    }


    // =========================================================
    // 4. 處理 InBody
    // =========================================================

    private void handleInBody(
            Attendance attendance,
            MemberCourse memberCourse,
            String status,
            InBodyRequest request
    ) {

        // 找這筆 Attendance 是否已經有 InBody
        Optional<InBodyRecord> existingRecord =
                inBodyRecordRepo
                        .findByAttendance_Attendanceid(
                                attendance.getAttendanceid()
                        );


        /*
        非 PRESENT
        如果之前有 InBody，
        現在改成 LEAVE / ABSENT，
        就刪除本次 Attendance 對應的 InBody。
        */

        if (!"PRESENT".equals(status)) {
            existingRecord.ifPresent(
                    inBodyRecordRepo::delete
            );
            return;
        }



        // PRESENT，但是三個 InBody 欄位全部沒填 → 不建立 InBody
        if (!hasInBodyValue(request)) {
            return;
        }


        /*
        如果已經有 InBody → 更新
        如果沒有 → 建立新的
        */
        InBodyRecord record =
                existingRecord.orElseGet(
                        InBodyRecord::new
                );


        // 關聯 Attendance
        record.setAttendance(attendance);

        // Member 由 MemberCourse 取得
        record.setMember(
                memberCourse.getMember()
        );

        // 日期由後端產生
        record.setRecorddate(
                LocalDate.now()
        );

        // DTO → Entity
        record.setWeight(
                request.getWeight()
        );

        record.setBodyfatpct(
                request.getBodyFatPct()
        );

        record.setMusclemass(
                request.getMuscleMass()
        );
        inBodyRecordRepo.save(record);
    }


    // =========================================================
    // 5. 判斷前端是否有輸入任何 InBody
    // =========================================================

    private boolean hasInBodyValue(
            InBodyRequest request
    ) {

        if (request == null) {
            return false;
        }


        /*
         * 只要其中一欄不是 null
         * 就代表使用者有輸入 InBody。
         *
         * 注意：
         * 0 不是 null。
         */
        return request.getWeight() != null
                || request.getBodyFatPct() != null
                || request.getMuscleMass() != null;
    }


    // =========================================================
    // 6. 取得某日 Attendance 工作台
    // GET /api/attendance?date=YYYY-MM-DD
    // =========================================================

    @Transactional(readOnly = true)
    public AttendanceListResponse getAttendanceList(
            LocalDate date,
            Integer coachId
    ) {

        // 1. 查指定日期 + 指定教練的 Booking
        List<Booking> bookings =
                bookingRepo
                        .findBySchedule_ClassdateAndMembercourse_Coach_Coachid(
                                date,
                                coachId
                        );



        //2. 排序
        /* 第一順位：startTime 升冪
         * 第二順位：bookingId 升冪
         */
        bookings.sort(
                Comparator
                        .comparing(
                                (Booking b) ->
                                        b.getSchedule()
                                                .getStarttime()
                        )
                        .thenComparing(
                                Booking::getBookingid
                        )
        );

        // 3. 準備卡片 List
        List<AttendanceCardResponse> cards =
                new ArrayList<>();


        // 4. 準備統計
        int pending = 0;
        int present = 0;
        int leave = 0;
        int absent = 0;
        int cancelled = 0;



        // 5. Booking → AttendanceCardResponse
        for (Booking booking : bookings) {


            // 查這筆 Booking 是否已有 Attendance
            Optional<Attendance> attendanceOptional =
                    attendanceRepo
                            .findByBooking_Bookingid(
                                    booking.getBookingid()
                            );


            /*
             * 沒有 Attendance：
             * 畫面仍然顯示 PENDING。
             *
             * GET 不會因此建立 Attendance。
             */
            String status =
                    attendanceOptional
                            .map(
                                    Attendance::getAttendancestatus
                            )
                            .orElse("PENDING");

            // MemberCourse
            MemberCourse memberCourse =
                    booking.getMembercourse();

            // 建 AttendanceCardResponse
            AttendanceCardResponse card =
                    new AttendanceCardResponse();

            // Booking.bookingid
            card.setBookingId(
                    booking.getBookingid()
            );

            // Booking.schedule.scheduleid
            card.setScheduleId(
                    booking.getSchedule()
                            .getScheduleid()
            );

            // ClassSchedule.starttime
            card.setStartTime(
                    booking.getSchedule()
                            .getStarttime()
            );

            // ClassSchedule.endtime
            card.setEndTime(
                    booking.getSchedule()
                            .getEndtime()
            );

            // MemberCourse.membercourseid
            card.setMemberCourseId(
                    memberCourse.getMembercourseid()
            );

            // Member.memberid
            card.setMemberId(
                    memberCourse.getMember()
                            .getMemberid()
            );

            // Member.name
            card.setMemberName(
                    memberCourse.getMember()
                            .getName()
            );

            // Member.avatarurl
            card.setAvatarUrl(
                    memberCourse.getMember()
                            .getAvatarurl()
            );

            // Course.coursename
            card.setCourseName(
                    memberCourse.getCourse()
                            .getCoursename()
            );

            // MemberCourse.remainingsessions
            card.setRemainingSessions(
                    memberCourse.getRemainingsessions()
            );

            // Booking.bookingstatus
            card.setBookingStatus(
                    booking.getBookingstatus()
            );

            // Attendance.attendancestatus
            // 沒 Attendance → PENDING
            card.setAttendanceStatus(status);

            // 加進回傳 List
            cards.add(card);



        // 6. 統計
            /*
             * Booking 已取消：
             *
             * 只算 cancelled。
             *
             * 不再重複算：
             * pending / present / leave / absent
             */
            boolean isCancelled =
                    "CANCELLED".equalsIgnoreCase(
                            booking.getBookingstatus()
                    );


            if (isCancelled) {
                cancelled++;
            } else {
                switch (status) {
                    case "PRESENT" ->
                            present++;
                    case "LEAVE" ->
                            leave++;
                    case "ABSENT" ->
                            absent++;
                    default ->
                            pending++;
                }
            }
        }

        // 7. 組 AttendanceSummaryResponse
        AttendanceSummaryResponse summary =
                new AttendanceSummaryResponse();
        /*
         * totalClasses：
         *
         * 當天回傳的 Booking 卡片總數
         *
         * 包含 cancelled。
         */
        summary.setTotalClasses(
                bookings.size()
        );

        summary.setPending(
                pending
        );

        summary.setPresent(
                present
        );

        summary.setLeave(
                leave
        );

        summary.setAbsent(
                absent
        );

        summary.setCancelled(
                cancelled
        );


        // 8. 組 AttendanceListResponse
        AttendanceListResponse response =
                new AttendanceListResponse();

        response.setDate(
                date
        );

        response.setSummary(
                summary
        );

        response.setClasses(
                cards
        );

        return response;
    }

    // =========================================================
    // 7. 取得單一 Attendance Detail
    // GET /api/attendance/{bookingId}
    // =========================================================

    @Transactional(readOnly = true)
    public AttendanceDetailResponse getAttendanceDetail(
            Integer bookingId,
            Integer coachId
    ) {


        // 1. 找 Booking
        Booking booking = bookingRepo.findById(bookingId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "找不到 Booking：" + bookingId
                        )
                );


        // 2. 取得 MemberCourse
        MemberCourse memberCourse =
                booking.getMembercourse();

        // 3. 確認這筆 MemberCourse 屬於目前教練
        // 目前 Controller 測試階段可以傳 coachId = 1。
        // 未來改由登入身分取得。

        if (!memberCourse.getCoach()
                .getCoachid()
                .equals(coachId)) {

            throw new ForbiddenException(
                    "無權限查看其他教練的學員"
            );
        }


        // 4. 建立最外層 Response
        AttendanceDetailResponse response =
                new AttendanceDetailResponse();

        response.setBookingId(
                booking.getBookingid()
        );



        // 5. ClassInfo
        AttendanceDetailResponse.ClassInfo classInfo =
                new AttendanceDetailResponse.ClassInfo();

        classInfo.setDate(
                booking.getSchedule()
                        .getClassdate()
        );

        classInfo.setStartTime(
                booking.getSchedule()
                        .getStarttime()
        );

        classInfo.setEndTime(
                booking.getSchedule()
                        .getEndtime()
        );

        response.setClassInfo(classInfo);


        // 6. MemberInfo
        AttendanceDetailResponse.MemberInfo memberInfo =
                new AttendanceDetailResponse.MemberInfo();

        memberInfo.setMemberId(
                memberCourse.getMember()
                        .getMemberid()
        );

        memberInfo.setName(
                memberCourse.getMember()
                        .getName()
        );

        memberInfo.setGender(
                memberCourse.getMember()
                        .getGender()
        );

        memberInfo.setPhone(
                memberCourse.getMember()
                        .getPhone()
        );

        memberInfo.setEmail(
                memberCourse.getMember()
                        .getEmail()
        );

        memberInfo.setAvatarUrl(
                memberCourse.getMember()
                        .getAvatarurl()
        );

        response.setMember(memberInfo);


        // 7. 找這個 MemberCourse 的 Attendance 歷史
        List<Attendance> attendanceHistory =
                attendanceRepo
                        .findByBooking_Membercourse_MembercourseidOrderByBooking_Schedule_ClassdateDesc(
                                memberCourse.getMembercourseid()
                        );

        /*
         * Repository 目前只保證 classdate DESC。
         * 如果同一天有兩堂課，
         * 再補 starttime + bookingid DESC，
         * 讓排序結果更穩定。
         */
        attendanceHistory.sort(
                Comparator
                        .comparing(
                                (Attendance a) ->
                                        a.getBooking()
                                                .getSchedule()
                                                .getClassdate()
                        )
                        .thenComparing(
                                a -> a.getBooking()
                                        .getSchedule()
                                        .getStarttime()
                        )
                        .thenComparing(
                                a -> a.getBooking()
                                        .getBookingid()
                        )
                        .reversed()
        );


        // 8. CourseInfo
        AttendanceDetailResponse.CourseInfo courseInfo =
                new AttendanceDetailResponse.CourseInfo();

        courseInfo.setMemberCourseId(
                memberCourse.getMembercourseid()
        );

        courseInfo.setCourseName(
                memberCourse.getCourse()
                        .getCoursename()
        );

        courseInfo.setTotalSessions(
                memberCourse.getTotalsessions()
        );

        courseInfo.setRemainingSessions(
                memberCourse.getRemainingsessions()
        );



        // 找最近一次 PRESENT 日期
        LocalDate lastPresentDate =
                attendanceHistory.stream()

                        .filter(a ->
                                "PRESENT".equals(
                                        a.getAttendancestatus()
                                )
                        )

                        .map(a ->
                                a.getBooking()
                                        .getSchedule()
                                        .getClassdate()
                        )

                        .findFirst()

                        .orElse(null);


        courseInfo.setLastPresentDate(
                lastPresentDate
        );

        response.setCourse(courseInfo);


        // 9. 本次 Attendance
        Optional<Attendance> attendanceOptional =
                attendanceRepo
                        .findByBooking_Bookingid(
                                bookingId
                        );


        AttendanceDetailResponse.AttendanceInfo attendanceInfo =
                new AttendanceDetailResponse.AttendanceInfo();


        // 情況 A：
        // 這筆 Booking 已經有 Attendance
        if (attendanceOptional.isPresent()) {

            Attendance attendance =
                    attendanceOptional.get();

            attendanceInfo.setAttendanceId(
                    attendance.getAttendanceid()
            );

            attendanceInfo.setStatus(
                    attendance.getAttendancestatus()
            );

            attendanceInfo.setCheckInTime(
                    attendance.getCheckintime()
            );

            attendanceInfo.setWorkoutFocus(
                    attendance.getWorkoutfocus()
            );

            attendanceInfo.setNote(
                    attendance.getNote()
            );

            // 查這筆 Attendance 是否有 InBody
            Optional<InBodyRecord> inBodyOptional =
                    inBodyRecordRepo
                            .findByAttendance_Attendanceid(
                                    attendance.getAttendanceid()
                            );

            if (inBodyOptional.isPresent()) {
                InBodyRecord record =
                        inBodyOptional.get();

                InBodyResponse inBodyResponse =
                        new InBodyResponse();


                // Entity.recorddate->DTO.recordDate
                inBodyResponse.setRecordDate(
                        record.getRecorddate()
                );

                inBodyResponse.setWeight(
                        record.getWeight()
                );

                // Entity.bodyfatpct->DTO.bodyFatPct
                inBodyResponse.setBodyFatPct(
                        record.getBodyfatpct()
                );

                // Entity.musclemass->DTO.muscleMass
                inBodyResponse.setMuscleMass(
                        record.getMusclemass()
                );

                attendanceInfo.setInBody(
                        inBodyResponse
                );

            } else {
                attendanceInfo.setInBody(null);
            }


            // -----------------------------------------------------
            // 情況 B：
            // 還沒有 Attendance
            // GET 不建立資料，
            // 只是在 Response 裡顯示 PENDING。
            // -----------------------------------------------------

        } else {
            attendanceInfo.setAttendanceId(null);
            attendanceInfo.setStatus(
                    "PENDING"
            );

            attendanceInfo.setCheckInTime(null);
            attendanceInfo.setWorkoutFocus(null);
            attendanceInfo.setNote(null);
            attendanceInfo.setInBody(null);
        }
        response.setAttendance(
                attendanceInfo
        );



        // 10. History
        // 同一個 MemberCourse
        // 排除目前這次 Booking
        // 最多最近 5 筆
        List<AttendanceHistoryResponse> history =
                attendanceHistory.stream()

                        // 排除目前正在看的 Booking
                        .filter(a ->
                                !a.getBooking()
                                        .getBookingid()
                                        .equals(bookingId)
                        )

                        // 最多 5 筆
                        .limit(5)

                        // Entity → DTO
                        .map(a -> {
                            AttendanceHistoryResponse item =
                                    new AttendanceHistoryResponse();

                            item.setDate(
                                    a.getBooking()
                                            .getSchedule()
                                            .getClassdate()
                            );

                            item.setStatus(
                                    a.getAttendancestatus()
                            );

                            item.setWorkoutFocus(
                                    a.getWorkoutfocus()
                            );

                            item.setNote(
                                    a.getNote()
                            );

                            return item;
                        })

                        .toList();

        response.setHistory(
                history
        );

        // 11. 回傳完整 Detail
        return response;
    }
}