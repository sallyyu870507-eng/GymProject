package tw.gymproject.service;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.util.Optional;

import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import tw.gymproject.dto.inbody.InBodyRequest;
import tw.gymproject.entity.Attendance;
import tw.gymproject.entity.InBodyRecord;
import tw.gymproject.entity.Membercourse;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.repository.AttendanceRepo;
import tw.gymproject.repository.BookingRepository;
import tw.gymproject.repository.InBodyRecordRepo;
import tw.gymproject.repository.MemberCourseRepo;

class AttendanceServiceInBodyClearTest {
    private AttendanceRepo attendanceRepo;
    private BookingRepository bookingRepo;
    private InBodyRecordRepo inBodyRecordRepo;
    private MemberCourseService memberCourseService;
    private MemberCourseRepo memberCourseRepo;
    private AttendanceService service;

    @BeforeEach
    void setUp() {
        attendanceRepo = mock(AttendanceRepo.class);
        bookingRepo = mock(BookingRepository.class);
        inBodyRecordRepo = mock(InBodyRecordRepo.class);
        memberCourseService = mock(MemberCourseService.class);
        memberCourseRepo = mock(MemberCourseRepo.class);
        service = new AttendanceService(
                attendanceRepo,
                bookingRepo,
                inBodyRecordRepo,
                memberCourseService,
                memberCourseRepo,
                mock(EntityManager.class)
        );
    }

    @Test
    void nullInBodyDeletesExistingRecord() {
        Attendance attendance = new Attendance();
        InBodyRecord existing = new InBodyRecord();
        when(inBodyRecordRepo.findByAttendance_Attendanceid(null))
                .thenReturn(Optional.of(existing));

        invokeHandleInBody(attendance, null);

        verify(inBodyRecordRepo).delete(existing);
    }

    @Test
    void allNullMeasurementsDeleteExistingRecord() {
        Attendance attendance = new Attendance();
        InBodyRecord existing = new InBodyRecord();
        when(inBodyRecordRepo.findByAttendance_Attendanceid(null))
                .thenReturn(Optional.of(existing));

        invokeHandleInBody(attendance, new InBodyRequest());

        verify(inBodyRecordRepo).delete(existing);
    }

    @Test
    void clearingWithoutExistingRecordAndClearingAgainBothSucceed() {
        Attendance attendance = new Attendance();
        InBodyRecord existing = new InBodyRecord();
        when(inBodyRecordRepo.findByAttendance_Attendanceid(null))
                .thenReturn(Optional.of(existing), Optional.empty());

        assertDoesNotThrow(() -> invokeHandleInBody(attendance, null));
        assertDoesNotThrow(() -> invokeHandleInBody(attendance, new InBodyRequest()));

        verify(inBodyRecordRepo).delete(existing);
    }

    @Test
    void partialMeasurementsStillFailValidationWithoutDeletingExistingRecord() {
        Attendance attendance = new Attendance();
        InBodyRecord existing = new InBodyRecord();
        InBodyRequest partial = new InBodyRequest();
        partial.setWeight(new java.math.BigDecimal("80"));
        when(inBodyRecordRepo.findByAttendance_Attendanceid(null))
                .thenReturn(Optional.of(existing));

        assertThrows(BusinessException.class,
                () -> invokeHandleInBody(attendance, partial));

        verify(inBodyRecordRepo, never()).delete(existing);
        verify(inBodyRecordRepo, never()).save(existing);
    }

    @Test
    void savingPresentAgainDoesNotChangeRemainingSessions() {
        ReflectionTestUtils.invokeMethod(
                service,
                "handleSessionChange",
                "PRESENT",
                "PRESENT",
                8
        );

        verifyNoInteractions(memberCourseService);
    }

    private void invokeHandleInBody(Attendance attendance, InBodyRequest request) {
        ReflectionTestUtils.invokeMethod(
                service,
                "handleInBody",
                attendance,
                new Membercourse(),
                "PRESENT",
                request,
                LocalDate.of(2026, 10, 15)
        );
    }
}
