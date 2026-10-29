package tw.gymproject.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tw.gymproject.dto.CoachDashboardDTO;
import tw.gymproject.dto.CoachScheduleDTO;
import tw.gymproject.dto.ScheduleOptionDTO;
import tw.gymproject.entity.Booking;
import tw.gymproject.entity.ClassSchedule;
import tw.gymproject.repository.BookingRepository;
import tw.gymproject.repository.ClassScheduleRepository;


@Service
public class BookingCoachService {


    // =====================================================
    // Repository
    // =====================================================

    private final ClassScheduleRepository classScheduleRepository;

    private final BookingRepository bookingRepository;


    public BookingCoachService(
            ClassScheduleRepository classScheduleRepository,
            BookingRepository bookingRepository) {

        this.classScheduleRepository =
                classScheduleRepository;

        this.bookingRepository =
                bookingRepository;
    }


    // =====================================================
    // 教練端：
    // 查指定日期已預約課表
    // =====================================================

    public List<CoachScheduleDTO> getBookedSchedules(
            Integer coachid,
            LocalDate classdate) {


        List<Object[]> results =
                classScheduleRepository
                        .findBookedSchedulesByCoachAndDate(
                                coachid,
                                classdate
                        );


        List<CoachScheduleDTO> dtoList =
                new ArrayList<>();


        for (Object[] row : results) {

            CoachScheduleDTO dto =
                    new CoachScheduleDTO();


            // row[0] = bookingid
            dto.setBookingid(
                    ((Number) row[0])
                            .intValue()
            );


            // row[1] = scheduleid
            dto.setScheduleid(
                    ((Number) row[1])
                            .intValue()
            );


            // row[2] = coursename
            dto.setCoursename(
                    (String) row[2]
            );


            // row[3] = studentname
            dto.setStudentname(
                    (String) row[3]
            );


            // row[4] = starttime
            dto.setStarttime(
                    ((java.sql.Time) row[4])
                            .toLocalTime()
            );


            // row[5] = endtime
            dto.setEndtime(
                    ((java.sql.Time) row[5])
                            .toLocalTime()
            );


            dtoList.add(dto);
        }


        return dtoList;
    }


    // =====================================================
    // 教練端：
    // Dashboard 統計
    // =====================================================

    public CoachDashboardDTO getDashboard(
            Integer coachid,
            LocalDate classdate) {


        Integer todayCourseCount =
                classScheduleRepository
                        .countTodayCourses(
                                coachid,
                                classdate
                        );


        Integer todayStudentCount =
                classScheduleRepository
                        .countTodayStudent(
                                coachid,
                                classdate
                        );


        CoachDashboardDTO dto =
                new CoachDashboardDTO();


        dto.setTodayCourseCount(
                todayCourseCount
        );


        dto.setTodayStudentCount(
                todayStudentCount
        );


        return dto;
    }


    // =====================================================
    // 教練端：
    // 取消預約
    //
    // 規則：
    // 課程尚未開始 → 可以取消
    // 課程已開始 → 不可取消
    // =====================================================

    @Transactional
    public String cancelBookingByCoach(
            Integer bookingid,
            Integer coachid) {


        // -------------------------------------------------
        // 1. 確認 booking 屬於目前教練
        // -------------------------------------------------

        int count =
                bookingRepository
                        .countBookingByCoach(
                                bookingid,
                                coachid
                        );


        if (count == 0) {

            throw new RuntimeException(
                    "找不到此筆預約，或此預約不屬於目前教練"
            );
        }


        // -------------------------------------------------
        // 2. 找 booking
        // -------------------------------------------------

        Booking booking =
                bookingRepository
                        .findById(
                                bookingid
                        )
                        .orElseThrow(
                                () ->
                                        new RuntimeException(
                                                "找不到此筆預約"
                                        )
                        );


        // -------------------------------------------------
        // 3. 必須是 booked
        // -------------------------------------------------

        if (!"booked".equals(
                booking.getBookingstatus()
        )) {

            throw new RuntimeException(
                    "此預約目前無法取消"
            );
        }


        // -------------------------------------------------
        // 4. 找課表
        // -------------------------------------------------

        ClassSchedule schedule =
                classScheduleRepository
                        .findById(
                                booking.getScheduleid()
                        )
                        .orElseThrow(
                                () ->
                                        new RuntimeException(
                                                "找不到此預約課表"
                                        )
                        );


        // -------------------------------------------------
        // 5. 課程日期 + 開始時間
        // -------------------------------------------------

        LocalDateTime classStartDateTime =
                LocalDateTime.of(
                        schedule.getClassdate(),
                        schedule.getStarttime()
                );


        // -------------------------------------------------
        // 6. 如果課程已經開始
        //    就不能取消
        //
        //    課程開始時間 <= 現在
        // -------------------------------------------------

        if (!classStartDateTime
                .isAfter(
                        LocalDateTime.now()
                )) {

            throw new RuntimeException(
                    "課程已開始，無法取消預約"
            );
        }


        // -------------------------------------------------
        // 7. 改狀態
        // -------------------------------------------------

        booking.setBookingstatus(
                "cancelled"
        );


        // -------------------------------------------------
        // 8. 更新修改時間
        // -------------------------------------------------

        booking.setUpdatetime(
                LocalDateTime.now()
        );


        // -------------------------------------------------
        // 9. 存回 DB
        // -------------------------------------------------

        bookingRepository.save(
                booking
        );


        return "教練代取消成功";
    }


    // =====================================================
    // 給 Controller 使用的取消方法
    //
    // Controller 如果目前呼叫：
    // coachCancelBooking(coachid, bookingid)
    //
    // 就會進到這裡
    // =====================================================

    public void coachCancelBooking(
            Integer coachid,
            Integer bookingid) {

        cancelBookingByCoach(
                bookingid,
                coachid
        );
    }


    // =====================================================
    // 教練修改預約：
    // 取得可以修改的日期
    //
    // 教練：
    // 今天可以修改
    // 明天以後也可以
    //
    // 但原課程如果已經開始
    // 就完全不能再修改
    // =====================================================

    public List<LocalDate>
    getAvailableDatesForReschedule(
            Integer coachid,
            Integer bookingid) {


        // -------------------------------------------------
        // 1. 確認預約是不是目前教練的
        // -------------------------------------------------

        int count =
                bookingRepository
                        .countBookingByCoach(
                                bookingid,
                                coachid
                        );


        if (count == 0) {

            throw new RuntimeException(
                    "找不到此預約，或此預約不屬於目前教練"
            );
        }


        // -------------------------------------------------
        // 2. 找 booking
        // -------------------------------------------------

        Booking booking =
                bookingRepository
                        .findById(
                                bookingid
                        )
                        .orElseThrow(
                                () ->
                                        new RuntimeException(
                                                "找不到此筆預約"
                                        )
                        );


        // -------------------------------------------------
        // 3. 必須是 booked
        // -------------------------------------------------

        if (!"booked".equals(
                booking.getBookingstatus()
        )) {

            throw new RuntimeException(
                    "此預約目前無法修改"
            );
        }


        // -------------------------------------------------
        // 4. 找原本課表
        // -------------------------------------------------

        ClassSchedule oldSchedule =
                classScheduleRepository
                        .findById(
                                booking.getScheduleid()
                        )
                        .orElseThrow(
                                () ->
                                        new RuntimeException(
                                                "找不到原本課表"
                                        )
                        );


        // -------------------------------------------------
        // 5. 原課程開始時間
        // -------------------------------------------------

        LocalDateTime oldClassStartDateTime =
                LocalDateTime.of(
                        oldSchedule.getClassdate(),
                        oldSchedule.getStarttime()
                );


        // -------------------------------------------------
        // 6. 原課程已經開始
        //    → 不可修改
        // -------------------------------------------------

        if (!oldClassStartDateTime
                .isAfter(
                        LocalDateTime.now()
                )) {

            throw new RuntimeException(
                    "課程已開始，無法修改預約"
            );
        }


        // -------------------------------------------------
        // 7. 找會員買的 courseid
        // -------------------------------------------------

        Integer courseid =
                bookingRepository
                        .findCourseidByMembercourseid(
                                booking.getMembercourseid()
                        );


        if (courseid == null) {

            throw new RuntimeException(
                    "找不到會員課程"
            );
        }


        // -------------------------------------------------
        // 8. 找會員課程綁定教練
        // -------------------------------------------------

        Integer memberCourseCoachid =
                bookingRepository
                        .findCoachidByMembercourseid(
                                booking.getMembercourseid()
                        );


        if (memberCourseCoachid == null) {

            throw new RuntimeException(
                    "找不到會員綁定教練"
            );
        }


        // -------------------------------------------------
        // 9. 必須是目前登入教練
        // -------------------------------------------------

        if (!coachid.equals(
                memberCourseCoachid
        )) {

            throw new RuntimeException(
                    "此會員課程不是綁定目前教練"
            );
        }


        // -------------------------------------------------
        // 10. 使用「教練專用」Repository
        //
        //     跟會員不同：
        //     教練可以查今天
        // -------------------------------------------------

        List<java.sql.Date> sqlDates =
                classScheduleRepository
                        .findCoachRescheduleAvailableDates(
                                courseid,
                                coachid
                        );


        // -------------------------------------------------
        // 11. java.sql.Date
        //     轉 LocalDate
        // -------------------------------------------------

        List<LocalDate> dates =
                sqlDates
                        .stream()
                        .map(
                                java.sql.Date::toLocalDate
                        )
                        .toList();


        return dates;
    }


    // =====================================================
    // 教練修改預約：
    // 選日期後查時段
    //
    // 今天已經開始的時段
    // 會改成 closed
    // =====================================================

    public List<ScheduleOptionDTO>
    getScheduleOptionsForReschedule(
            Integer coachid,
            Integer bookingid,
            LocalDate date) {


        // -------------------------------------------------
        // 1. 日期不可是過去
        //
        // 今天可以
        // -------------------------------------------------

        if (
            date == null ||
            date.isBefore(
                    LocalDate.now()
            )
        ) {

            throw new RuntimeException(
                    "新的預約日期不能是今天以前"
            );
        }


        // -------------------------------------------------
        // 2. 確認預約屬於登入教練
        // -------------------------------------------------

        int count =
                bookingRepository
                        .countBookingByCoach(
                                bookingid,
                                coachid
                        );


        if (count == 0) {

            throw new RuntimeException(
                    "找不到此預約，或此預約不屬於目前教練"
            );
        }


        // -------------------------------------------------
        // 3. 找 booking
        // -------------------------------------------------

        Booking booking =
                bookingRepository
                        .findById(
                                bookingid
                        )
                        .orElseThrow(
                                () ->
                                        new RuntimeException(
                                                "找不到此筆預約"
                                        )
                        );


        // -------------------------------------------------
        // 4. 必須 booked
        // -------------------------------------------------

        if (!"booked".equals(
                booking.getBookingstatus()
        )) {

            throw new RuntimeException(
                    "此預約目前無法修改"
            );
        }


        // -------------------------------------------------
        // 5. 找原本課表
        // -------------------------------------------------

        ClassSchedule oldSchedule =
                classScheduleRepository
                        .findById(
                                booking.getScheduleid()
                        )
                        .orElseThrow(
                                () ->
                                        new RuntimeException(
                                                "找不到原本課表"
                                        )
                        );


        // -------------------------------------------------
        // 6. 原課程已經開始
        //    → 不可以再改
        // -------------------------------------------------

        LocalDateTime oldClassStartDateTime =
                LocalDateTime.of(
                        oldSchedule.getClassdate(),
                        oldSchedule.getStarttime()
                );


        if (!oldClassStartDateTime
                .isAfter(
                        LocalDateTime.now()
                )) {

            throw new RuntimeException(
                    "課程已開始，無法修改預約"
            );
        }


        // -------------------------------------------------
        // 7. 找 courseid
        // -------------------------------------------------

        Integer courseid =
                bookingRepository
                        .findCourseidByMembercourseid(
                                booking.getMembercourseid()
                        );


        if (courseid == null) {

            throw new RuntimeException(
                    "找不到會員課程"
            );
        }


        // -------------------------------------------------
        // 8. 使用「教練專用」查詢
        //
        // 今天也可以查
        // -------------------------------------------------

        List<Object[]> rows =
                classScheduleRepository
                        .findCoachRescheduleScheduleOptions(
                                courseid,
                                coachid,
                                date
                        );


        List<ScheduleOptionDTO> result =
                new ArrayList<>();


        // -------------------------------------------------
        // 9. Object[] → DTO
        // -------------------------------------------------

        for (Object[] row : rows) {


            ScheduleOptionDTO dto =
                    new ScheduleOptionDTO();


            Integer scheduleid =
                    ((Number) row[0])
                            .intValue();


            java.time.LocalTime starttime =
                    ((java.sql.Time) row[1])
                            .toLocalTime();


            java.time.LocalTime endtime =
                    ((java.sql.Time) row[2])
                            .toLocalTime();


            String status =
                    (String) row[3];


            // ---------------------------------------------
            // 10. 如果選的是今天
            //
            // 現在已經超過這個時段開始時間
            // → status 改成 closed
            //
            // 例如現在 10:30
            //
            // 09:00 → closed
            // 10:00 → closed
            // 11:00 → 繼續看原本 status
            // ---------------------------------------------

            if (date.equals(
                    LocalDate.now()
            )) {


                LocalDateTime slotStartDateTime =
                        LocalDateTime.of(
                                date,
                                starttime
                        );


                if (!slotStartDateTime
                        .isAfter(
                                LocalDateTime.now()
                        )) {

                    status =
                            "closed";
                }
            }


            dto.setScheduleid(
                    scheduleid
            );


            dto.setStarttime(
                    starttime
            );


            dto.setEndtime(
                    endtime
            );


            dto.setStatus(
                    status
            );


            result.add(dto);
        }


        return result;
    }


    // =====================================================
    // 教練修改預約：
    // 真正修改 scheduleid
    // =====================================================

    @Transactional
    public String rescheduleBookingByCoach(
            Integer bookingid,
            Integer coachid,
            Integer newScheduleid) {


        // -------------------------------------------------
        // 1. 防呆
        // -------------------------------------------------

        if (newScheduleid == null) {

            throw new RuntimeException(
                    "請選擇新的預約時段"
            );
        }


        // -------------------------------------------------
        // 2. 確認預約屬於目前教練
        // -------------------------------------------------

        int count =
                bookingRepository
                        .countBookingByCoach(
                                bookingid,
                                coachid
                        );


        if (count == 0) {

            throw new RuntimeException(
                    "找不到此預約，或此預約不屬於目前教練"
            );
        }


        // -------------------------------------------------
        // 3. 找 booking
        // -------------------------------------------------

        Booking booking =
                bookingRepository
                        .findById(
                                bookingid
                        )
                        .orElseThrow(
                                () ->
                                        new RuntimeException(
                                                "找不到此筆預約"
                                        )
                        );


        // -------------------------------------------------
        // 4. 只有 booked 可以修改
        // -------------------------------------------------

        if (!"booked".equals(
                booking.getBookingstatus()
        )) {

            throw new RuntimeException(
                    "此預約目前無法修改"
            );
        }


        // -------------------------------------------------
        // 5. 找原本課表
        // -------------------------------------------------

        ClassSchedule oldSchedule =
                classScheduleRepository
                        .findById(
                                booking.getScheduleid()
                        )
                        .orElseThrow(
                                () ->
                                        new RuntimeException(
                                                "找不到原本課表"
                                        )
                        );


        // -------------------------------------------------
        // 6. 原課程開始時間
        // -------------------------------------------------

        LocalDateTime oldClassStartDateTime =
                LocalDateTime.of(
                        oldSchedule.getClassdate(),
                        oldSchedule.getStarttime()
                );


        // -------------------------------------------------
        // 7. 原課程已經開始
        //    → 不能修改
        // -------------------------------------------------

        if (!oldClassStartDateTime
                .isAfter(
                        LocalDateTime.now()
                )) {

            throw new RuntimeException(
                    "課程已開始，無法修改預約"
            );
        }


        // -------------------------------------------------
        // 8. 找新課表
        // -------------------------------------------------

        ClassSchedule newSchedule =
                classScheduleRepository
                        .findById(
                                newScheduleid
                        )
                        .orElseThrow(
                                () ->
                                        new RuntimeException(
                                                "找不到新的課表"
                                        )
                        );


        // -------------------------------------------------
        // 9. 新課表開始時間
        // -------------------------------------------------

        LocalDateTime newClassStartDateTime =
                LocalDateTime.of(
                        newSchedule.getClassdate(),
                        newSchedule.getStarttime()
                );


        // -------------------------------------------------
        // 10. 新時段必須晚於現在
        // -------------------------------------------------

        if (!newClassStartDateTime
                .isAfter(
                        LocalDateTime.now()
                )) {

            throw new RuntimeException(
                    "新的預約時段必須晚於現在時間"
            );
        }


        // -------------------------------------------------
        // 11. 不可以選原本相同 schedule
        // -------------------------------------------------

        if (booking
                .getScheduleid()
                .equals(
                        newScheduleid
                )) {

            throw new RuntimeException(
                    "新的日期時間與原本預約相同"
            );
        }


        // -------------------------------------------------
        // 12. 課程不可更換
        // -------------------------------------------------

        if (!oldSchedule
                .getCourseid()
                .equals(
                        newSchedule.getCourseid()
                )) {

            throw new RuntimeException(
                    "修改預約時不能更換課程"
            );
        }


        // -------------------------------------------------
        // 13. 教練不可更換
        // -------------------------------------------------

        if (!oldSchedule
                .getCoachid()
                .equals(
                        newSchedule.getCoachid()
                )) {

            throw new RuntimeException(
                    "修改預約時不能更換教練"
            );
        }


        // -------------------------------------------------
        // 14. 新時段必須是目前登入教練
        // -------------------------------------------------

        if (!coachid.equals(
                newSchedule.getCoachid()
        )) {

            throw new RuntimeException(
                    "新的時段不屬於目前教練"
            );
        }


        // -------------------------------------------------
        // 15. 課表必須 open
        // -------------------------------------------------

        if (!"open".equals(
                newSchedule.getStatus()
        )) {

            throw new RuntimeException(
                    "新的時段目前無法預約"
            );
        }


        // -------------------------------------------------
        // 16. 新時段不能已經有人 booked
        // -------------------------------------------------

        boolean alreadyBooked =
                bookingRepository
                        .existsByScheduleidAndBookingstatus(
                                newScheduleid,
                                "booked"
                        );


        if (alreadyBooked) {

            throw new RuntimeException(
                    "新的時段已經被其他會員預約"
            );
        }


        // -------------------------------------------------
        // 17. 修改 booking 的 scheduleid
        // -------------------------------------------------

        booking.setScheduleid(
                newScheduleid
        );


        // -------------------------------------------------
        // 18. 更新修改時間
        // -------------------------------------------------

        booking.setUpdatetime(
                LocalDateTime.now()
        );


        // -------------------------------------------------
        // 19. 儲存
        // -------------------------------------------------

        bookingRepository.save(
                booking
        );


        return "教練修改預約日期時間成功";
    }


    // =====================================================
    // 給我們剛剛 Controller 使用
    //
    // Controller 呼叫：
    //
    // rescheduleBooking(
    //     coachid,
    //     bookingid,
    //     newScheduleid
    // )
    // =====================================================

    public void rescheduleBooking(
            Integer coachid,
            Integer bookingid,
            Integer newScheduleid) {


        rescheduleBookingByCoach(
                bookingid,
                coachid,
                newScheduleid
        );
    }

}