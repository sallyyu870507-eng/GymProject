package tw.gymproject.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.AdminCoachDTO;
import tw.gymproject.dto.AdminScheduleDTO;
import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.service.AdminScheduleService;


@RestController
@RequestMapping("/api/admin/schedules")
public class AdminScheduleController {

    private final AdminScheduleService adminScheduleService;


    public AdminScheduleController(
            AdminScheduleService adminScheduleService) {

        this.adminScheduleService =
                adminScheduleService;
    }


    // =====================================================
    // 1. 查某一天全館所有教練排課
    //
    // GET
    // /api/admin/schedules/day?date=YYYY-MM-DD
    // =====================================================

    @GetMapping("/day")
    public List<AdminScheduleDTO> getScheduleByDate(
            @RequestParam LocalDate date,
            HttpSession session) {


        // 1. 從 Session 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO)
                session.getAttribute(
                        "user"
                );


        // 2. 確認是否登入
        if (user == null) {

            throw new RuntimeException(
                    "管理員尚未登入"
            );
        }


        // 3. 確認是不是管理員
        if (!"admin".equals(
                user.getRole()
        )) {

            throw new RuntimeException(
                    "沒有管理員權限"
            );
        }


        // 4. 查某一天全館所有教練排課
        return adminScheduleService
                .getAdminScheduleByDate(
                        date
                );
    }


    // =====================================================
    // 2. 取得所有教練
    //
    // GET
    // /api/admin/schedules/coaches
    // =====================================================

    @GetMapping("/coaches")
    public List<AdminCoachDTO> getAllCoaches(
            HttpSession session) {


        // 1. 從 Session 取得正式登入者
        LoginResultDTO user =
                (LoginResultDTO)
                session.getAttribute(
                        "user"
                );


        // 2. 確認是否登入
        if (user == null) {

            throw new RuntimeException(
                    "管理員尚未登入"
            );
        }


        // 3. 確認是不是管理員
        if (!"admin".equals(
                user.getRole()
        )) {

            throw new RuntimeException(
                    "沒有管理員權限"
            );
        }


        // 4. 查全部教練
        return adminScheduleService
                .getAllCoaches();
    }
}