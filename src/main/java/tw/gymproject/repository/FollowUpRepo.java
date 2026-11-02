package tw.gymproject.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import tw.gymproject.entity.FollowUp;
import java.util.Optional;
import java.util.List;

public interface FollowUpRepo
        extends JpaRepository<FollowUp, Integer> {

    // 查某教練的指定關懷狀態
    List<FollowUp> findByCoach_CoachidAndStatus(
            Integer coachid,
            String status
    );

    // 查某個方案的全部關懷紀錄
    List<FollowUp>
    findByMemberCourse_MembercourseidOrderByCreatedateDesc(
            Integer membercourseid
    );

    // 工作台、方案詳情沿用：
    // 查目前教練所負責方案，各自最新的一筆關懷紀錄
    @Query("""
            select f
            from FollowUp f
            where f.memberCourse.coach.coachid = :coachId
              and not exists (
                  select newer.followupid
                  from FollowUp newer
                  where newer.memberCourse = f.memberCourse
                    and (
                        newer.createdate > f.createdate
                        or (
                            f.createdate is null
                            and newer.createdate is not null
                        )
                        or (
                            (
                                newer.createdate = f.createdate
                                or (
                                    newer.createdate is null
                                    and f.createdate is null
                                )
                            )
                            and newer.followupid > f.followupid
                        )
                    )
              )
            """)
    List<FollowUp> findLatestForCoachPlans(
            @Param("coachId") Integer coachId
    );

    // 新增：指定方案的關懷紀錄，於資料庫端分頁
    // 排序：
    // 1. 有聯繫時間的排前面，null 排最後
    // 2. 聯繫時間由新到舊
    // 3. 時間相同時，ID 由大到小
    //
    // 同時讀取每筆紀錄自己的教練資料
    @Query(
            value = """
                    select f
                    from FollowUp f
                    join fetch f.coach
                    where f.memberCourse.membercourseid = :memberCourseId
                    order by
                        case when f.createdate is null then 1 else 0 end,
                        f.createdate desc,
                        f.followupid desc
                    """,
            countQuery = """
                    select count(f)
                    from FollowUp f
                    where f.memberCourse.membercourseid = :memberCourseId
                    """
    )
    Page<FollowUp> findPageByMemberCourseId(
            @Param("memberCourseId") Integer memberCourseId,
            Pageable pageable
    );

    // 查指定方案中的單筆關懷紀錄
    @Query("""
        select f
        from FollowUp f
        join fetch f.coach
        where f.followupid = :followupId
          and f.memberCourse.membercourseid = :memberCourseId
        """)
    Optional<FollowUp> findDetailByIdAndMemberCourseId(
            @Param("followupId") Integer followupId,
            @Param("memberCourseId") Integer memberCourseId
    );
}