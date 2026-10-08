package tw.gym.service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import tw.gym.dto.AdminCoachDTO;
import tw.gym.dto.AdminScheduleDTO;
import tw.gym.repository.ClassScheduleRepository;

@Service
public class AdminScheduleService {

    // 管理員端 service
    private final ClassScheduleRepository classScheduleRepository;


    public AdminScheduleService(
            ClassScheduleRepository classScheduleRepository) {

        this.classScheduleRepository =
                classScheduleRepository;
    }



    /* =================================
       1. 管理員查某一天全館所有教練排課
    ================================= */

    public List<AdminScheduleDTO> getAdminScheduleByDate(
            LocalDate classdate) {


        List<Object[]> results =
                classScheduleRepository
                        .findAdminSchedulesByDate(classdate);


        List<AdminScheduleDTO> dtoList =
                new ArrayList<>();


        for (Object[] row : results) {

            AdminScheduleDTO dto =
                    new AdminScheduleDTO();


            dto.setScheduleid(
                    ((Number) row[0]).intValue()
            );


            dto.setCoachid(
                    ((Number) row[1]).intValue()
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


            dto.setStatus(
                    (String) row[6]
            );


            dto.setMembername(
                    (String) row[7]
            );


            dto.setCoursename(
                    (String) row[8]
            );


            dtoList.add(dto);

        }


        return dtoList;
    }



    /* =================================
       2. 管理員取得所有教練
    ================================= */

    public List<AdminCoachDTO> getAllCoaches() {


        List<Object[]> results =
                classScheduleRepository
                        .findAllCoachesForAdmin();


        List<AdminCoachDTO> coachList =
                new ArrayList<>();


        for (Object[] row : results) {


            AdminCoachDTO dto =
                    new AdminCoachDTO();


            dto.setCoachid(
                    ((Number) row[0]).intValue()
            );


            dto.setCoachname(
                    (String) row[1]
            );


            coachList.add(dto);

        }


        return coachList;
    }

}