package tw.gymproject.dto.member;

import java.time.LocalDate;

/** GET /api/member/courses：會員買的課程方案與剩餘堂數 */
public record MemberCourseResponse(
        Integer membercourseid,
        String coursename,
        String coachname,
        Integer totalsessions,
        Integer remainingsessions,
        LocalDate purchasedate,
        String status) {
}
