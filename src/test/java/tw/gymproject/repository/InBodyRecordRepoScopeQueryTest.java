package tw.gymproject.repository;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.Query;

class InBodyRecordRepoScopeQueryTest {
    @Test
    void allInBodyQueriesContainTheSamePlanAndCoachMemberScopePredicates() throws Exception {
        var pageQuery = InBodyRecordRepo.class
                .getMethod("findInBodyPage", Integer.class, Integer.class, Integer.class,
                        String.class, java.time.LocalDate.class, java.time.LocalTime.class,
                        org.springframework.data.domain.Pageable.class)
                .getAnnotation(Query.class);
        assertValidRecordPredicates(pageQuery.value());
        assertValidRecordPredicates(pageQuery.countQuery());
        assertValidRecordPredicates(InBodyRecordRepo.class
                .getMethod("findDatedInBody", Integer.class, Integer.class, Integer.class,
                        String.class, java.time.LocalDate.class, java.time.LocalTime.class,
                        String.class, org.springframework.data.domain.Pageable.class)
                .getAnnotation(Query.class).value());
        String anomalyQuery = InBodyRecordRepo.class
                .getMethod("findInBodyAnomalies", Integer.class, Integer.class, Integer.class,
                        String.class, java.time.LocalDate.class, java.time.LocalTime.class)
                .getAnnotation(Query.class).value();
        assertScopePredicates(anomalyQuery);
        assertTrue(anomalyQuery.toLowerCase().contains("'not_present;'"));
    }

    @Test
    void pagedAndTrendQueriesUseUniqueInBodyIdAsFinalSortKey() throws Exception {
        String pageQuery = InBodyRecordRepo.class
                .getMethod("findInBodyPage", Integer.class, Integer.class, Integer.class,
                        String.class, java.time.LocalDate.class, java.time.LocalTime.class,
                        org.springframework.data.domain.Pageable.class)
                .getAnnotation(Query.class).value().toLowerCase();
        String trendQuery = InBodyRecordRepo.class
                .getMethod("findDatedInBody", Integer.class, Integer.class, Integer.class,
                        String.class, java.time.LocalDate.class, java.time.LocalTime.class,
                        String.class, org.springframework.data.domain.Pageable.class)
                .getAnnotation(Query.class).value().toLowerCase();

        assertTrue(pageQuery.contains("i.inbodyid desc"));
        assertTrue(trendQuery.contains("i.inbodyid desc"));
    }

    private void assertScopePredicates(String query) {
        String normalized = query.toLowerCase().replaceAll("\\s+", " ");
        assertTrue(normalized.contains("(:scope = 'plan' and b.membercourseid = :membercourseid)"));
        assertTrue(normalized.contains(":scope = 'coach_member' and mc.memberid = :memberid and mc.coachid = :coachid"));
    }

    private void assertValidRecordPredicates(String query) {
        String normalized = query.toLowerCase().replaceAll("\\s+", " ");
        assertScopePredicates(query);
        assertTrue(normalized.contains("i.memberid = mc.memberid"));
        assertTrue(normalized.contains("a.attendancestatus = 'present'"));
        assertTrue(normalized.contains("lower(b.bookingstatus) <> 'cancelled'"));
    }
}
