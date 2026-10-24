package tw.gymproject.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.RoundingMode;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;

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
import tw.gymproject.entity.Membercourse;


import tw.gymproject.repository.AttendanceRepo;
import tw.gymproject.repository.BookingRepo;
import tw.gymproject.repository.InBodyRecordRepo;
import tw.gymproject.repository.MemberCourseRepo;

import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ResourceNotFoundException;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.exception.ConflictException;




@Service
public class AttendanceService {

    private static final ZoneId TAIPEI_ZONE =
            ZoneId.of("Asia/Taipei");
    private final AttendanceRepo attendanceRepo;
    private final BookingRepo bookingRepo;
    private final InBodyRecordRepo inBodyRecordRepo;
    private final MemberCourseService memberCourseService;
    private final MemberCourseRepo memberCourseRepo;
    private final EntityManager entityManager;

    public AttendanceService(
            AttendanceRepo attendanceRepo,
            BookingRepo bookingRepo,
            InBodyRecordRepo inBodyRecordRepo,
            MemberCourseService memberCourseService,
            MemberCourseRepo memberCourseRepo,
            EntityManager entityManager
    ) {
        this.attendanceRepo = attendanceRepo;
        this.bookingRepo = bookingRepo;
        this.inBodyRecordRepo = inBodyRecordRepo;
        this.memberCourseService = memberCourseService;
        this.memberCourseRepo = memberCourseRepo;
        this.entityManager = entityManager;
    }

    // =========================================================
    // 1. 更新 Attendance
    //PUT /api/coach/attendance/{bookingId}
    // =========================================================
    @Transactional
    public AttendanceDetailResponse updateAttendance(
            Integer bookingId,
            Integer coachId,
            AttendanceUpdateRequest request
    ) {
        // 1. 驗證基本輸入
        if (bookingId == null || bookingId <= 0) {
            throw new BusinessException(
                    "bookingId 必須為正整數"
            );
        }

        if (request == null) {
            throw new BusinessException(
                    "請提供出席更新內容"
            );
        }

        String newStatus = request.getStatus();
        validateAttendanceStatus(newStatus);

        validateTextLength(
                request.getWorkoutFocus(),
                50,
                "訓練內容"
        );

        validateTextLength(
                request.getNote(),
                100,
                "出席備註"
        );

        // 2. 鎖定預約。
        // 同一筆預約的更新，必須等待前一筆交易結束。
        Booking booking = bookingRepo
                .findByIdForUpdate(bookingId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "找不到 Booking：" + bookingId
                        )
                );

        // 3. 取得方案 ID，不先讀取堂數。
        Integer memberCourseId = booking
                .getMembercourse()
                .getMembercourseid();

        // 4. 鎖定方案。
        // 不同預約若屬於同一方案，也必須依序調整堂數。
        Membercourse memberCourse = memberCourseRepo
                .findByIdForUpdate(memberCourseId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "找不到 Membercourse：" + memberCourseId
                        )
                );

        // 確保使用鎖定後的資料庫最新值，
        // 避免沿用本次請求中已載入的舊方案資料。
        entityManager.refresh(
                memberCourse,
                LockModeType.PESSIMISTIC_WRITE
        );

        // 5. 權限檢查
        if (!memberCourse.getCoach()
                .getCoachid()
                .equals(coachId)) {

            throw new ForbiddenException(
                    "無權限修改其他教練的學員"
            );
        }

        // 6. 已取消的預約不能修改出席
        if ("CANCELLED".equalsIgnoreCase(
                booking.getBookingstatus()
        )) {
            throw new ConflictException(
                    "已取消的預約不能更新出席"
            );
        }

        // 7. 取得出席紀錄。
        // 在取得預約鎖定後，才讀取目前的出席狀態。
        Attendance attendance = attendanceRepo
                .findByBooking_Bookingid(bookingId)
                .orElseGet(() -> {
                    Attendance newAttendance = new Attendance();
                    newAttendance.setBooking(booking);
                    newAttendance.setAttendancestatus("PENDING");
                    return newAttendance;
                });

        // 已存在的紀錄重新載入，避免使用先前載入的舊狀態。
        if (attendance.getAttendanceid() != null) {
            entityManager.refresh(attendance);
        }

        String oldStatus = attendance.getAttendancestatus();

        // 8. 沿用原本扣堂、補堂與方案狀態同步邏輯
        handleSessionChange(
                oldStatus,
                newStatus,
                memberCourseId
        );

        // 9. 更新出席內容
        LocalDateTime now = LocalDateTime.now(TAIPEI_ZONE);

        attendance.setAttendancestatus(newStatus);
        attendance.setWorkoutfocus(request.getWorkoutFocus());
        attendance.setNote(request.getNote());
        attendance.setUpdatetime(now);

        // 第一次改為出席才設定報到時間。
        // 已經出席再送出，不重設原報到時間。
        if ("PRESENT".equals(newStatus)) {
            if (!"PRESENT".equals(oldStatus)) {
                attendance.setCheckintime(now);
            }
        } else {
            attendance.setCheckintime(null);
        }

        Attendance savedAttendance =
                attendanceRepo.save(attendance);

        // 10. 沿用原本 InBody 建立、修改及刪除邏輯
        handleInBody(
                savedAttendance,
                memberCourse,
                newStatus,
                request.getInBody(),
                booking.getSchedule().getClassdate()
        );

        // 11. 回傳更新後詳情
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
    //InBody 規則：
    /*
         PRESENT + inBody = null
        → 通過 validate
        → hasInBodyValue = false
        → return
        → 不建立、不改既有 InBody

        PRESENT + 三個都有值
        → 通過 validate
        → hasInBodyValue = true
        → 建立或更新 InBody

        PRESENT + 只填 1～2 個
        → validateCompleteInBody()
        → BusinessException
     */
    // =========================================================
    // 4. 處理 InBody
    // =========================================================
    private void handleInBody(
            Attendance attendance,
            Membercourse memberCourse,
            String status,
            InBodyRequest request,
            LocalDate classDate
    ) {

        // 找這筆 Attendance 是否已經有 InBody
        Optional<InBodyRecord> existingRecord =
                inBodyRecordRepo
                        .findByAttendance_Attendanceid(
                                attendance.getAttendanceid()
                        );

        /*
         * 非 PRESENT：
         * 如果之前有 InBody，
         * 改成 LEAVE / ABSENT 時就刪除。
         */
        if (!"PRESENT".equals(status)) {
            existingRecord.ifPresent(
                    inBodyRecordRepo::delete
            );
            return;
        }

        /*
         * PRESENT：
         * 要嘛 inBody 完全不填，
         * 要嘛 weight / bodyFatPct / muscleMass 三個都要填。
         */
        validateCompleteInBody(request);

        // 完全沒有輸入 InBody → 不建立，也不修改既有 InBody
        if (!hasInBodyValue(request)) {
            return;
        }

        /*
         * 已經有 InBody → 更新原本那筆
         * 沒有 → 建立新的
         */
        InBodyRecord record =
                existingRecord.orElseGet(
                        InBodyRecord::new
                );

        // 關聯 Attendance
        record.setAttendance(attendance);

        // Member 由 Membercourse 取得
        record.setMember(
                memberCourse.getMember()
        );

        // 量測歸屬該次上課日，允許事後補登或更正。
        record.setRecorddate(classDate);

        // 完整更新這次 InBody
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

    private boolean hasInBodyValue(InBodyRequest request) {

        if (request == null) {
            return false;
        }

        return request.getWeight() != null
                || request.getBodyFatPct() != null
                || request.getMuscleMass() != null;
    }

    private void validateCompleteInBody(InBodyRequest request) {

        // 沒有量 InBody
        // inBody = null → 合法
        if (request == null) {
            return;
        }


        boolean anyValue =
                request.getWeight() != null
                        || request.getBodyFatPct() != null
                        || request.getMuscleMass() != null;

        boolean allValues =
                request.getWeight() != null
                        && request.getBodyFatPct() != null
                        && request.getMuscleMass() != null;

        /*
         * 有傳 InBody 時，
         * weight / bodyFatPct / muscleMass
         * 三個欄位必須全部有值。
         */
        if (anyValue && !allValues) {
            throw new BusinessException(
                    "InBody 資料需完整填寫體重、體脂率與肌肉量"
            );
        }

        /*
         * 完全沒填任何數值
         * 交給 hasInBodyValue() 判斷後 return。
         */
        if (!anyValue) {
            return;
        }

        /*
         * 數值必須大於 0。
         */
        if (request.getWeight().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException(
                    "體重必須大於 0"
            );
        }

        if (request.getBodyFatPct().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException(
                    "體脂率必須大於 0"
            );
        }

        if (request.getMuscleMass().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException(
                    "肌肉量必須大於 0"
            );
        }

        validateDecimalStorage(
                request.getWeight(),
                new BigDecimal("999.99"),
                2,
                "體重"
        );

        validateDecimalStorage(
                request.getBodyFatPct(),
                new BigDecimal("999.9"),
                1,
                "體脂率"
        );

        validateDecimalStorage(
                request.getMuscleMass(),
                new BigDecimal("999.9"),
                1,
                "肌肉量"
        );
    }

    // =========================================================
    // 6. 取得某日 Attendance 工作台
    // GET /api/coach/attendance?date=YYYY-MM-DD
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

            // Membercourse
            Membercourse memberCourse =
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

            // Membercourse.membercourseid
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

            // Membercourse.remainingsessions
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
             * 只算 cancelled。
             * 不再重複算：pending / present / leave / absent
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
         * 當天回傳的 Booking 卡片總數
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
    // GET /api/coach/attendance/{bookingId}
    // =========================================================

    @Transactional(readOnly = true)
    public AttendanceDetailResponse getAttendanceDetail(
            Integer bookingId,
            Integer coachId
    ) {
        if (bookingId == null || bookingId <= 0) {
            throw new BusinessException(
                    "bookingId 必須為正整數"
            );
        }


        // 1. 找 Booking
        Booking booking = bookingRepo.findById(bookingId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "找不到 Booking：" + bookingId
                        )
                );


        // 2. 取得 Membercourse
        Membercourse memberCourse =
                booking.getMembercourse();

        // 3. 確認這筆 Membercourse 屬於目前教練
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


        // 7. 找這個 Membercourse 的 Attendance 歷史
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
        // 同一個 Membercourse
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


    // SQL Server NVARCHAR(n) 的容量以 UTF-16 單位計算。
    // Java String.length() 可用來檢查此限制。
    private void validateTextLength(
            String value,
            int maxLength,
            String fieldName
    ) {
        if (value != null && value.length() > maxLength) {
            throw new BusinessException(
                    fieldName + "不可超過 "
                            + maxLength + " 個 UTF-16 單位"
            );
        }
    }

    // 避免數值超出 DECIMAL 範圍，
    // 或由資料庫自動四捨五入而改變使用者輸入。
    private void validateDecimalStorage(
            BigDecimal value,
            BigDecimal maxValue,
            int decimalPlaces,
            String fieldName
    ) {
        if (value == null) {
            return;
        }

        if (value.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException(
                    fieldName + "必須大於 0"
            );
        }

        if (value.compareTo(maxValue) > 0) {
            throw new BusinessException(
                    fieldName + "不可大於 "
                            + maxValue.toPlainString()
            );
        }

        try {
            value.setScale(
                    decimalPlaces,
                    RoundingMode.UNNECESSARY
            );
        } catch (ArithmeticException ex) {
            throw new BusinessException(
                    fieldName + "最多允許 "
                            + decimalPlaces + " 位有效小數"
            );
        }
    }


}
