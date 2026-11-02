package tw.gymproject.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mindrot.jbcrypt.BCrypt;
import org.mockito.MockMakers;
import org.springframework.web.server.ResponseStatusException;
import tw.gymproject.dto.CoachCreateRequest;
import tw.gymproject.dto.CoachStatusRequest;
import tw.gymproject.entity.Coach;
import tw.gymproject.entity.Useraccount;
import tw.gymproject.repository.AccountRepository;
import tw.gymproject.repository.CoachRepository;

class CoachManagementServiceTest {
    private CoachRepository coaches;
    private AccountRepository accounts;
    private CoachManagementService service;

    @BeforeEach
    void setUp() {
        coaches = mock(CoachRepository.class, withSettings().mockMaker(MockMakers.SUBCLASS));
        accounts = mock(AccountRepository.class, withSettings().mockMaker(MockMakers.SUBCLASS));
        service = new CoachManagementService(coaches, accounts);
    }

    private CoachCreateRequest request() {
        CoachCreateRequest request = new CoachCreateRequest();
        request.setCoachno(" C901 ");
        request.setName(" Iris ");
        request.setPhone(" 0912345678 ");
        return request;
    }

    @Test
    void createsLinkedCoachAccountWithHashedInitialPassword() {
        when(accounts.save(any(Useraccount.class))).thenAnswer(call -> {
            Useraccount account = call.getArgument(0);
            account.setAccountid(901);
            return account;
        });
        when(coaches.save(any(Coach.class))).thenAnswer(call -> call.getArgument(0));

        Coach coach = service.createCoach(request());
        Useraccount account = coach.getAccount();
        assertEquals("C901", coach.getCoachno());
        assertEquals("Iris", account.getUsername());
        assertEquals("0912345678", coach.getPhone());
        assertEquals("coach", account.getRole());
        assertEquals("active", account.getStatus());
        assertEquals("active", coach.getStatus());
        assertEquals(901, coach.getAccountid());
        assertNotEquals(coach.getPhone(), account.getPassword());
        assertTrue(BCrypt.checkpw(coach.getPhone(), account.getPassword()));
    }

    @Test
    void duplicateUsernameCannotCreateEitherRecord() {
        when(accounts.existsByUsername("Iris")).thenReturn(true);
        ResponseStatusException failure = assertThrows(ResponseStatusException.class,
                () -> service.createCoach(request()));
        assertEquals(409, failure.getStatusCode().value());
        verify(accounts, never()).save(any());
        verify(coaches, never()).save(any());
    }

    @Test
    void duplicateCoachNumberCannotCreateAccount() {
        when(coaches.existsByCoachno("C901")).thenReturn(true);
        assertThrows(ResponseStatusException.class, () -> service.createCoach(request()));
        verifyNoInteractions(accounts);
        verify(coaches, never()).save(any());
    }

    @Test
    void disablingAndReactivatingCoachAlsoUpdatesAccount() {
        Useraccount account = new Useraccount();
        Coach coach = new Coach();
        coach.setAccount(account);
        when(coaches.findById(901)).thenReturn(Optional.of(coach));
        for (String status : new String[] { "inactive", "active" }) {
            CoachStatusRequest request = new CoachStatusRequest();
            request.setStatus(status);
            service.updateCoachStatus(901, request);
            assertEquals(status, coach.getStatus());
            assertEquals(status, account.getStatus());
        }
        verify(accounts, times(2)).save(account);
        verify(coaches, times(2)).save(coach);
    }
}
