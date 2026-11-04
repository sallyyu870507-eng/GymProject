package tw.gymproject.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import tw.gymproject.entity.Coach;
import tw.gymproject.entity.Member;
import tw.gymproject.entity.Membercourse;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.repository.InBodyRecordRepo;
import tw.gymproject.repository.MemberCourseRepo;

class InBodyQueryServiceScopeTest {
    private MemberCourseRepo memberCourseRepo;
    private InBodyRecordRepo inBodyRecordRepo;
    private InBodyQueryService service;

    @BeforeEach
    void setUp() {
        memberCourseRepo = mock(MemberCourseRepo.class);
        inBodyRecordRepo = mock(InBodyRecordRepo.class);
        service = new InBodyQueryService(memberCourseRepo, inBodyRecordRepo);
    }

    @Test
    void crossPlanQueriesUseMemberFromAuthorizedPlanAndCoachFromSessionForEveryDataset() {
        when(memberCourseRepo.findOverviewById(42)).thenReturn(Optional.of(plan(7, 3)));
        when(inBodyRecordRepo.findInBodyAnomalies(eq(42), eq(7), eq(3), eq("COACH_MEMBER"),
                any(LocalDate.class), any(LocalTime.class))).thenReturn(List.of());
        when(inBodyRecordRepo.findInBodyPage(eq(42), eq(7), eq(3), eq("COACH_MEMBER"),
                any(LocalDate.class), any(LocalTime.class), any()))
                .thenAnswer(call -> new PageImpl<>(List.of(), call.getArgument(6), 11));
        when(inBodyRecordRepo.findDatedInBody(eq(42), eq(7), eq(3), eq("COACH_MEMBER"),
                any(LocalDate.class), any(LocalTime.class), any(), any())).thenReturn(List.of());

        var response = service.getInBody(3, 42, 2, 5, "COACH_MEMBER");

        assertEquals("COACH_MEMBER", response.getScope());
        assertEquals(2, response.getPage().getNumber());
        assertEquals(11, response.getPage().getTotalElements());
        verify(inBodyRecordRepo).findInBodyPage(eq(42), eq(7), eq(3), eq("COACH_MEMBER"),
                any(LocalDate.class), any(LocalTime.class), eq(PageRequest.of(0, 5)));
        verify(inBodyRecordRepo).findInBodyPage(eq(42), eq(7), eq(3), eq("COACH_MEMBER"),
                any(LocalDate.class), any(LocalTime.class), eq(PageRequest.of(1, 5)));
        verify(inBodyRecordRepo).findInBodyAnomalies(eq(42), eq(7), eq(3), eq("COACH_MEMBER"),
                any(LocalDate.class), any(LocalTime.class));
        for (String metric : List.of("ALL", "WEIGHT", "BODY_FAT", "MUSCLE_MASS")) {
            verify(inBodyRecordRepo).findDatedInBody(eq(42), eq(7), eq(3), eq("COACH_MEMBER"),
                    any(LocalDate.class), any(LocalTime.class), eq(metric), any());
        }
    }

    @Test
    void omittedScopeDefaultsToPlanAndInvalidScopeIsRejected() {
        when(memberCourseRepo.findOverviewById(42)).thenReturn(Optional.of(plan(7, 3)));
        when(inBodyRecordRepo.findInBodyAnomalies(eq(42), eq(7), eq(3), eq("PLAN"),
                any(LocalDate.class), any(LocalTime.class))).thenReturn(List.of());
        when(inBodyRecordRepo.findInBodyPage(eq(42), eq(7), eq(3), eq("PLAN"),
                any(LocalDate.class), any(LocalTime.class), any()))
                .thenReturn(new PageImpl<>(List.of()));
        when(inBodyRecordRepo.findDatedInBody(eq(42), eq(7), eq(3), eq("PLAN"),
                any(LocalDate.class), any(LocalTime.class), any(), any())).thenReturn(List.of());

        assertEquals("PLAN", service.getInBody(3, 42, 1, 5, null).getScope());
        clearInvocations(inBodyRecordRepo);
        assertThrows(BusinessException.class, () -> service.getInBody(3, 42, 1, 5, "ALL"));
        verifyNoInteractionsAfterInvalidScope();
    }

    @Test
    void planOwnedByDifferentCoachIsRejectedBeforeAnyInBodyQuery() {
        when(memberCourseRepo.findOverviewById(42)).thenReturn(Optional.of(plan(7, 99)));

        assertThrows(ForbiddenException.class,
                () -> service.getInBody(3, 42, 1, 5, "COACH_MEMBER"));

        verifyNoInteractions(inBodyRecordRepo);
    }

    private Membercourse plan(int memberId, int coachId) {
        Member member = new Member();
        member.setMemberid(memberId);
        Coach coach = new Coach();
        coach.setCoachid(coachId);
        Membercourse plan = new Membercourse();
        plan.setMember(member);
        plan.setCoach(coach);
        return plan;
    }

    private void verifyNoInteractionsAfterInvalidScope() {
        verify(inBodyRecordRepo, never()).findInBodyAnomalies(any(), any(), any(), any(), any(), any());
        verify(inBodyRecordRepo, never()).findInBodyPage(any(), any(), any(), any(), any(), any(), any());
        verify(inBodyRecordRepo, never()).findDatedInBody(any(), any(), any(), any(), any(), any(), any(), any());
    }
}
