package tw.gymproject.service;

import java.sql.Date;
import java.sql.Time;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import tw.gymproject.dto.BookingResponseDTO;
import tw.gymproject.entity.Booking;
import tw.gymproject.entity.ClassSchedule;
import tw.gymproject.repository.BookingRepository;
import tw.gymproject.repository.ClassScheduleRepository;

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
    public BookingResponseDTO createBooking(
            Booking booking,
            Integer memberid) {

        /*
         * 1. 確認這筆 membercourse
         *    真的屬於目前登入的會員
         */
        List<Object[]> memberCourseRows =
                bookingRepository
                        .findCourseAndCoachByMembercourseidAndMemberid(
                                booking.getMembercourseid(),
                                memberid
                        );

        if (memberCourseRows.isEmpty()) {
            throw new RuntimeException(
                    "此會員課程不屬於目前登入會員"
            );
        }


        /* 2. 查會員這筆課程剩餘堂數 */
        Integer remainingSessions =
                bookingRepository
                        .findRemainingSessionsByMembercourseid(
                                booking.getMembercourseid()
                        );


        /* 3. 找不到 membercourse */
        if (remainingSessions == null) {
            throw new RuntimeException(
                    "找不到會員課程"
            );
        }


        /* 4. 剩餘堂數必須大於 0 */
        if (remainingSessions <= 0) {

            throw new RuntimeException(
                    "剩餘課堂數不足，無法預約"
            );
        }


        /* 5. 查會員購買的是哪個課程 */
        Integer memberCourseCourseid =
                bookingRepository
                        .findCourseidByMembercourseid(
                                booking.getMembercourseid()
                        );

        if (memberCourseCourseid == null) {

            throw new RuntimeException(
                    "找不到會員課程"
            );
        }


        /* 6. 查會員這筆課程綁定哪一位教練 */
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


        /* 7. 查要預約的課表 */
        ClassSchedule schedule =
                classScheduleRepository
                        .findById(
                                booking.getScheduleid()
                        )
                        .orElseThrow(
                                () -> new RuntimeException(
                                        "找不到這個課表"
                                )
                        );
        /*今天以前的日期不能預約*/
        if(!schedule.getClassdate().isAfter(LocalDate.now())) {
        	throw new RuntimeException("今天及今天以前的日期無法預約");
        }


        /*
         * 8. 會員買的課程必須和課表課程一致
         */
        if (!memberCourseCourseid.equals(
                schedule.getCourseid()
        )) {

            throw new RuntimeException(
                    "會員購買的課程與預約的課程不符"
            );
        }


        /*
         * 9. 會員綁定的教練
         *    必須和課表教練一致
         */
        if (!memberCourseCoachid.equals(
                schedule.getCoachid()
        )) {

            throw new RuntimeException(
                    "會員綁定的教練與預約教練不符"
            );
        }


        /* 10. 課表必須是 open */
        if (!"open".equals(
                schedule.getStatus()
        )) {

            throw new RuntimeException(
                    "這個時段目前不能預約"
            );
        }


        /*
         * 11. 同一時段
         *     不能有兩筆有效預約
         */
        if (isScheduleBooked(
                booking.getScheduleid()
        )) {

            throw new RuntimeException(
                    "這個時段已經被預約了"
            );
        }


        /*
         * 12. 系統自動設定
         *     預約狀態與時間
         */
        booking.setBookingstatus("booked");
        booking.setBookingtime(
                LocalDateTime.now()
        );
        booking.setUpdatetime(
                LocalDateTime.now()
        );


        /* 13. 儲存 booking */
        Booking savedBooking =
                bookingRepository.save(
                        booking
                );


        /*
         * 14. 查預約完成後
         *     要回傳給前端的完整資料
         */
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


        Object[] row = rows.get(0);


        /* 15. 組成 BookingResponseDTO */
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


        /* 16. 回傳給 Controller */
        return dto;
    }


    /* 會員查詢自己的預約 */
    public List<BookingResponseDTO> getMyBookings(
            Integer memberid) {

        List<Object[]> rows =
                bookingRepository
                        .findBookingsByMemberid(
                                memberid
                        );


        List<BookingResponseDTO> result =
                new ArrayList<>();


        for (Object[] row : rows) {

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
                    convertToLocalDate(
                            row[3]
                    )
            );

            dto.setStarttime(
                    convertToLocalTime(
                            row[4]
                    )
            );

            dto.setEndtime(
                    convertToLocalTime(
                            row[5]
                    )
            );

            dto.setClassroom(
                    row[6] == null
                            ? null
                            : row[6].toString()
            );

            dto.setBookingstatus(
                    (String) row[7]
            );

            result.add(dto);
        }


        return result;
    }


    /*
     * SQL Date / LocalDate
     * 都可以轉成 LocalDate
     */
    private LocalDate convertToLocalDate(
            Object value) {

        if (value == null) {
            return null;
        }

        if (value instanceof LocalDate) {
            return (LocalDate) value;
        }

        if (value instanceof Date) {
            return ((Date) value)
                    .toLocalDate();
        }

        return LocalDate.parse(
                value.toString()
        );
    }


    /*
     * SQL Time / LocalTime
     * 都可以轉成 LocalTime
     */
    private LocalTime convertToLocalTime(
            Object value) {

        if (value == null) {
            return null;
        }

        if (value instanceof LocalTime) {
            return (LocalTime) value;
        }

        if (value instanceof Time) {
            return ((Time) value)
                    .toLocalTime();
        }

        return LocalTime.parse(
                value.toString()
        );
    }


    /* 會員取消預約 */
    public String cancelBooking(
            Integer bookingid,
            Integer memberid) {

        /*
         * 1. 先確認這筆預約
         *    是不是目前會員自己的
         */
        int count =
                bookingRepository
                        .countBookingByMember(
                                bookingid,
                                memberid
                        );

        if (count == 0) {

            throw new RuntimeException(
                    "找不到此預約，或此預約不屬於目前的會員"
            );
        }


        /* 2. 找到這筆預約 */
        Booking booking =
                bookingRepository
                        .findById(bookingid)
                        .orElseThrow(
                                () -> new RuntimeException(
                                        "找不到此筆預約"
                                )
                        );


        /* 3. 只有 booked 可以取消 */
        if (!"booked".equals(
                booking.getBookingstatus()
        )) {

            throw new RuntimeException(
                    "此預約無法取消"
            );
        }


        /* 4. 改狀態 */
        booking.setBookingstatus(
                "cancelled"
        );


        /* 5. 更新最後修改時間 */
        booking.setUpdatetime(
                LocalDateTime.now()
        );


        /* 6. 存回資料庫 */
        bookingRepository.save(
                booking
        );


        return "取消預約成功";
    }
    
    /*會員修改日期時間*/
    
    public String rescheduleBooking(
    		Integer bookingid,
    		Integer memberid,
    		Integer newScheduleid) {
    	
    	//1.確認這筆資料是不是會員自己的
    	
    	int count =
    		bookingRepository.countBookingByMember(bookingid, memberid);
    	
    	if(count==0) {
    		throw new RuntimeException("找不到此預約，獲此預約不屬於目前會員");
    	}
    	
    	//2.找原本的booking
    	Booking booking =
    			bookingRepository.findById(bookingid)
    			.orElseThrow(
    					()->new RuntimeException("找不到此筆預約"));
    	
    	//3.只有booked可以修改
    	if(!"booked".equals(booking.getBookingstatus())) {
    		throw new RuntimeException(
    				"此預約目前無法修改");
    	}
    	
    	//4.找原本的課表
    	ClassSchedule oldSchedule =
    			classScheduleRepository
    			.findById(booking.getScheduleid())
    			.orElseThrow(
    					()-> new RuntimeException(
    							"找不到原本的課表"));
    	
    	// 5. 只能修改明天之後的預約
    	if (!oldSchedule.getClassdate().isAfter(LocalDate.now())) {

    	    throw new RuntimeException(
    	            "今天及今天以前的預約無法修改"
    	    );
    	}
    	//6.找新的課表
    	ClassSchedule newSchedule =
    			classScheduleRepository
    			.findById(newScheduleid)
    			.orElseThrow(
    					()->new RuntimeException(
    							"找不到新的課表"));
    	
    	if (!newSchedule.getClassdate().isAfter(LocalDate.now())) {

    	    throw new RuntimeException(
    	            "新的預約日期必須是明天之後"
    	    );
    	}
    	
    	//7.不能選原本相同的時段
    	if(booking.getScheduleid()
    			.equals(newScheduleid)) {
    		throw new RuntimeException(
    				"新的日期時間與原本的時間相同");
    	}
    	
    	//8.不能換課程
    	if(!oldSchedule.getCourseid()
    			.equals(newSchedule.getCourseid())) {
    		throw new RuntimeException(
    				"修改預約時不能更換課程");
    		
    	}
    	
    	//9.不能換教練
    	if(!oldSchedule.getCoachid()
    			.equals(newSchedule.getCoachid())) {
    		throw new RuntimeException(
    				"修改預約時不能更換教練");
    	}
    	
    	//10.新時段必須open
    	if(!"open".equals(newSchedule.getStatus())) {
    		throw new RuntimeException(
    				"新時段無法預約");
    	}
    	
    	//11.新時段不能被預約
    	boolean alreadyBooked=
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
    	
    	// 12. 更新成新的 scheduleid
        booking.setScheduleid(
                newScheduleid
        );


        // 13. 更新修改時間
        booking.setUpdatetime(
                LocalDateTime.now()
        );


        // 14. 存回資料庫
        bookingRepository.save(
                booking
        );


        return "修改預約成功";
    }
}