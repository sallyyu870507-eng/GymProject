package tw.gymproject.repository;


/*
1. 查某次 Attendance 對應的 InBody
2. 查某位會員的 InBody 歷史趨勢

規則:
只有 PRESENT 才可能有 InBody
而且 inbodyrecords.attendanceid 會指向那一次 Attendance
 */


import org.springframework.data.jpa.repository.JpaRepository;
import tw.gymproject.entity.InBodyRecord;

import java.util.List;
import java.util.Optional;

public interface InBodyRecordRepo extends JpaRepository<InBodyRecord, Integer> {

    // 查某一次 Attendance 是否有 InBody (一次 Attendance 最多一筆 InBody。)
    Optional<InBodyRecord> findByAttendance_Attendanceid(
            Integer attendanceid
    );

    // 查某位會員所有 InBody 紀錄，日期由新到舊
    List<InBodyRecord> findByMember_MemberidOrderByRecorddateDesc(
            Integer memberid
    );
}