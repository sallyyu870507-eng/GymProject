package tw.gymproject.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import tw.gymproject.entity.InBodyRecord;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

public interface InBodyRecordRepo
        extends JpaRepository<InBodyRecord, Integer> {

    // 查某一次 Attendance 是否有 InBody (一次 Attendance 最多一筆 InBody。)
    Optional<InBodyRecord> findByAttendance_Attendanceid(
            Integer attendanceid
    );

    // 查某位會員所有 InBody 紀錄，日期由新到舊
    List<InBodyRecord> findByMember_MemberidOrderByRecorddateDesc(
            Integer memberid
    );

    // B2 共用回傳欄位
    String B2_COLUMNS = """
            select
                i.inbodyid as inBodyId,
                i.attendanceid as attendanceId,
                i.recorddate as recordDate,
                s.classdate as classDate,
                s.starttime as classStartTime,
                i.weight as weight,
                i.bodyfatpct as bodyFatPct,
                i.musclemass as muscleMass
            """;

    // B2 有效集合：
    // 指定方案、會員一致、PRESENT、未取消、課程已開始、
    // 至少一個數值，以及量測日期不是未來
    String B2_FROM_WHERE = """
            from inbodyrecords i
            join attendance a
                on a.attendanceid = i.attendanceid
            join booking b
                on b.bookingid = a.bookingid
            join membercourse mc
                on mc.membercourseid = b.membercourseid
            join classschedule s
                on s.scheduleid = b.scheduleid
            where b.membercourseid = :memberCourseId
              and i.memberid = mc.memberid
              and a.attendancestatus = 'PRESENT'
              and lower(b.bookingstatus) <> 'cancelled'
              and (
                  s.classdate < cast(:asOfDate as date)
                  or (
                      s.classdate = cast(:asOfDate as date)
                      and s.starttime <= cast(:asOfTime as time)
                  )
              )
              and (
                  i.weight is not null
                  or i.bodyfatpct is not null
                  or i.musclemass is not null
              )
              and (
                  i.recorddate is null
                  or i.recorddate <= cast(:asOfDate as date)
              )
            """;

    // B2：表格分頁
    // 有日期：量測日期、上課日期時間、ID 由新到舊
    // 無日期：排最後，只按 ID 由大到小
    @Query(
            value = B2_COLUMNS + B2_FROM_WHERE + """
                    order by
                        case when i.recorddate is null then 1 else 0 end,
                        i.recorddate desc,
                        case when i.recorddate is not null
                            then s.classdate else null end desc,
                        case when i.recorddate is not null
                            then s.starttime else null end desc,
                        i.inbodyid desc
                    """,
            countQuery = "select count_big(*) " + B2_FROM_WHERE,
            nativeQuery = true
    )
    Page<InBodyRow> findPlanInBodyPage(
            @Param("memberCourseId") Integer memberCourseId,
            @Param("asOfDate") LocalDate asOfDate,
            @Param("asOfTime") LocalTime asOfTime,
            Pageable pageable
    );

    // B2：只查有日期的有效量測
    //
    // metric:
    // ALL         → 最新量測摘要
    // WEIGHT      → 體重非 null
    // BODY_FAT    → 體脂率非 null
    // MUSCLE_MASS → 肌肉量非 null
    //
    // 使用 Pageable 限制筆數；Service 只傳入上述固定代碼
    @Query(
            value = B2_COLUMNS + B2_FROM_WHERE + """
                    and i.recorddate is not null
                    and (
                        :metric = 'ALL'
                        or (
                            :metric = 'WEIGHT'
                            and i.weight is not null
                        )
                        or (
                            :metric = 'BODY_FAT'
                            and i.bodyfatpct is not null
                        )
                        or (
                            :metric = 'MUSCLE_MASS'
                            and i.musclemass is not null
                        )
                    )
                    order by
                        i.recorddate desc,
                        s.classdate desc,
                        s.starttime desc,
                        i.inbodyid desc
                    """,
            nativeQuery = true
    )
    List<InBodyRow> findDatedPlanInBody(
            @Param("memberCourseId") Integer memberCourseId,
            @Param("asOfDate") LocalDate asOfDate,
            @Param("asOfTime") LocalTime asOfTime,
            @Param("metric") String metric,
            Pageable pageable
    );

    // 接收查詢結果，不是 Entity，不建立資料表
    interface InBodyRow {

        Integer getInBodyId();

        Integer getAttendanceId();

        LocalDate getRecordDate();

        LocalDate getClassDate();

        LocalTime getClassStartTime();

        BigDecimal getWeight();

        BigDecimal getBodyFatPct();

        BigDecimal getMuscleMass();
    }

    // 查指定方案中，不符合 B2 規則的量測紀錄
    @Query(
            value = """
                select
                    i.inbodyid as inBodyId,
                    i.attendanceid as attendanceId,
                    concat(
                        case
                            when i.memberid <> mc.memberid
                            then 'MEMBER_MISMATCH;'
                            else ''
                        end,
                        case
                            when a.attendancestatus is null
                              or a.attendancestatus <> 'PRESENT'
                            then 'NOT_PRESENT;'
                            else ''
                        end,
                        case
                            when b.bookingstatus is null
                              or lower(b.bookingstatus) = 'cancelled'
                            then 'INVALID_BOOKING_STATUS;'
                            else ''
                        end,
                        case
                            when s.classdate is null
                              or s.starttime is null
                            then 'MISSING_CLASS_TIME;'
                            else ''
                        end,
                        case
                            when s.classdate > cast(:asOfDate as date)
                              or (
                                  s.classdate = cast(:asOfDate as date)
                                  and s.starttime > cast(:asOfTime as time)
                              )
                            then 'CLASS_NOT_STARTED;'
                            else ''
                        end,
                        case
                            when i.weight is null
                             and i.bodyfatpct is null
                             and i.musclemass is null
                            then 'ALL_VALUES_NULL;'
                            else ''
                        end,
                        case
                            when i.recorddate > cast(:asOfDate as date)
                            then 'FUTURE_RECORD_DATE;'
                            else ''
                        end
                    ) as reasons

                from inbodyrecords i
                join attendance a
                    on a.attendanceid = i.attendanceid
                join booking b
                    on b.bookingid = a.bookingid
                join membercourse mc
                    on mc.membercourseid = b.membercourseid
                join classschedule s
                    on s.scheduleid = b.scheduleid

                where b.membercourseid = :memberCourseId
                  and (
                      i.memberid <> mc.memberid
                      or a.attendancestatus is null
                      or a.attendancestatus <> 'PRESENT'
                      or b.bookingstatus is null
                      or lower(b.bookingstatus) = 'cancelled'
                      or s.classdate is null
                      or s.starttime is null
                      or s.classdate > cast(:asOfDate as date)
                      or (
                          s.classdate = cast(:asOfDate as date)
                          and s.starttime > cast(:asOfTime as time)
                      )
                      or (
                          i.weight is null
                          and i.bodyfatpct is null
                          and i.musclemass is null
                      )
                      or i.recorddate > cast(:asOfDate as date)
                  )
                order by i.inbodyid
                """,
            nativeQuery = true
    )
    List<InBodyAnomaly> findPlanInBodyAnomalies(
            @Param("memberCourseId") Integer memberCourseId,
            @Param("asOfDate") LocalDate asOfDate,
            @Param("asOfTime") LocalTime asOfTime
    );

    interface InBodyAnomaly {

        Integer getInBodyId();

        Integer getAttendanceId();

        String getReasons();
    }

}