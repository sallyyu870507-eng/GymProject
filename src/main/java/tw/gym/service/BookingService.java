package tw.gym.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;

import tw.gym.dto.BookingResponseDTO;
import tw.gym.entity.Booking;
import tw.gym.entity.ClassSchedule;
import tw.gym.repository.BookingRepository;
import tw.gym.repository.ClassScheduleRepository;

@Service
public class BookingService {

    private final BookingRepository bookingRepository;
    private final ClassScheduleRepository classScheduleRepository;

    public BookingService(
            BookingRepository bookingRepository,
            ClassScheduleRepository classScheduleRepository) {

        this.bookingRepository = bookingRepository;
        this.classScheduleRepository = classScheduleRepository;
    }

    /* 查這個時段是否已經有人預約 */
    public boolean isScheduleBooked(Integer scheduleid) {

        return bookingRepository
                .existsByScheduleidAndBookingstatus(
                        scheduleid,
                        "booked"
                );
    }

    /* 建立預約 */
    public BookingResponseDTO createBooking(Booking booking) {

        /* 1. 查會員這筆課程剩餘堂數 */
        Integer remainingSessions =
                bookingRepository
                        .findRemainingSessionsByMembercourseid(
                                booking.getMembercourseid()
                        );

        /* 2. 找不到 membercourse */
        if (remainingSessions == null) {
            throw new RuntimeException("找不到會員課程");
        }

        /* 3. 剩餘堂數必須大於 0 */
        if (remainingSessions <= 0) {
            throw new RuntimeException(
                    "剩餘課堂數不足，無法預約"
            );
        }

        /* 4. 查會員購買的是哪個課程 */
        Integer memberCourseCourseid =
                bookingRepository
                        .findCourseidByMembercourseid(
                                booking.getMembercourseid()
                        );

        if (memberCourseCourseid == null) {
            throw new RuntimeException("找不到會員課程");
        }
        
        /* 5.查會員這筆課程綁定哪一位教練 */
        Integer memberCourseCoachid =
                bookingRepository
                        .findCoachidByMembercourseid(
                                booking.getMembercourseid()
                        );

        if (memberCourseCoachid == null) {

            throw new RuntimeException(
                    "找不到會員綁定的教練"
            );
        }


        /* 6. 查要預約的課表 */
        ClassSchedule schedule =
                classScheduleRepository
                        .findById(booking.getScheduleid())
                        .orElseThrow(
                                () -> new RuntimeException(
                                        "找不到這個課表"
                                )
                        );

        /* 7. 會員買的課程必須和課表課程一致 */
        if (!memberCourseCourseid.equals(
                schedule.getCourseid()
        )) {

            throw new RuntimeException(
                    "會員購買的課程與預約的課程不符"
            );
        }
        
        /* 8.STEP6：檢查教練是否一致 */
        if (!memberCourseCoachid.equals(
                schedule.getCoachid())) {

            throw new RuntimeException(
                    "會員綁定的教練與預約教練不符"
            );
        }

        /* 9. 課表必須是 open */
        if (!"open".equals(schedule.getStatus())) {

            throw new RuntimeException(
                    "這個時段目前不能預約"
            );
        }

        /* 10. 同一時段不能重複有效預約 */
        if (isScheduleBooked(
                booking.getScheduleid()
        )) {

            throw new RuntimeException(
                    "這個時段已經被預約了"
            );
        }

        /* 11. 系統自動設定狀態與時間 */
        booking.setBookingstatus("booked");
        booking.setBookingtime(LocalDateTime.now());
        booking.setUpdatetime(LocalDateTime.now());

        /* 12. 儲存 */
        Booking savedBooking =
                bookingRepository.save(booking);
        
        /* 13. 查預約成功頁完整資料 */
        List<Object[]> rows =
                bookingRepository
                        .findBookingResponseByBookingid(
                                savedBooking.getBookingid()
                        );

        if (rows.isEmpty()) {
            throw new RuntimeException(
                    "預約成功，但無法取得預約詳細資料"
            );
        }
        
        Object[] row =rows.get(0);

        /* 13. 組成 BookingResponseDTO */
        BookingResponseDTO dto =
                new BookingResponseDTO();

        dto.setBookingid(
                ((Number) row[0]).intValue()
        );

        dto.setCoursename(
                (String) row[1]
        );

        dto.setCoachname(
                (String) row[2]
        );

        dto.setClassdate(
                ((java.sql.Date) row[3])
                        .toLocalDate()
        );

        dto.setStarttime(
                ((java.sql.Time) row[4])
                        .toLocalTime()
        );

        dto.setEndtime(
                ((java.sql.Time) row[5])
                        .toLocalTime()
        );

        dto.setClassroom(
                (String) row[6]
        );

        dto.setBookingstatus(
                (String) row[7]
        );

        /* 13. 回傳給 Controller */
        return dto;
    }
}