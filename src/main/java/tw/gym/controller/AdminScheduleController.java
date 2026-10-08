package tw.gym.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpSession;
import tw.gym.dto.AdminCoachDTO;
import tw.gym.dto.AdminScheduleDTO;
import tw.gym.service.AdminScheduleService;

@RestController
@RequestMapping("/admin/schedules")

// 管理員端 controller
public class AdminScheduleController {

    private final AdminScheduleService adminScheduleService;


    public AdminScheduleController(
            AdminScheduleService adminScheduleService) {

        this.adminScheduleService =
                adminScheduleService;
    }



    /* =================================
       1. 查某一天全館所有教練排課
    ================================= */

    @GetMapping("/day")
    public List<AdminScheduleDTO> getScheduleByDate(
            @RequestParam LocalDate date,
            HttpSession session) {


        String role =
                (String) session.getAttribute("role");


        if (!"admin".equals(role)) {

            throw new RuntimeException(
                    "沒有管理員權限"
            );

        }


        return adminScheduleService
                .getAdminScheduleByDate(date);
    }



    /* =================================
       2. 取得所有教練
    ================================= */

    @GetMapping("/coaches")
    public List<AdminCoachDTO> getAllCoaches(
            HttpSession session) {


        String role =
                (String) session.getAttribute("role");


        if (!"admin".equals(role)) {

            throw new RuntimeException(
                    "沒有管理員權限"
            );

        }


        return adminScheduleService
                .getAllCoaches();
    }

}