package tw.gymproject.repository;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import tw.gymproject.entity.Booking;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface BookingRepo extends JpaRepository<Booking, Integer> {

    // 查指定日期、屬於指定教練的預約列表
    List<Booking> findBySchedule_ClassdateAndMembercourse_Coach_Coachid(
            LocalDate classdate,
            Integer coachid
    );

    // 更新出席前鎖定預約。
    // 必須在 Service 的 @Transactional 方法內呼叫。
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select b
            from Booking b
            where b.bookingid = :bookingId
            """)
    Optional<Booking> findByIdForUpdate(
            @Param("bookingId") Integer bookingId
    );
}