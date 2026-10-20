package tw.gymproject.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import tw.gymproject.dto.renewal.InBodyPageResponse;
import tw.gymproject.entity.MemberCourse;
import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ForbiddenException;
import tw.gymproject.exception.ResourceNotFoundException;
import tw.gymproject.repository.InBodyRecordRepo;
import tw.gymproject.repository.MemberCourseRepo;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class InBodyQueryService {

    private static final Logger log =
            LoggerFactory.getLogger(InBodyQueryService.class);

    private static final ZoneId TAIPEI =
            ZoneId.of("Asia/Taipei");

    private static final int PAGE_SIZE = 5;

    private static final int TREND_LIMIT = 6;

    private final MemberCourseRepo memberCourseRepo;
    private final InBodyRecordRepo inBodyRecordRepo;

    public InBodyQueryService(
            MemberCourseRepo memberCourseRepo,
            InBodyRecordRepo inBodyRecordRepo
    ) {
        this.memberCourseRepo = memberCourseRepo;
        this.inBodyRecordRepo = inBodyRecordRepo;
    }

    @Transactional(
            readOnly = true,
            isolation = Isolation.SERIALIZABLE
    )
    public InBodyPageResponse getInBody(
            Integer coachId,
            Integer memberCourseId,
            Integer page,
            Integer size
    ) {
        // 同一次請求固定使用同一個台北時間
        LocalDateTime asOfDateTime =
                LocalDateTime.now(TAIPEI);

        LocalDate asOfDate =
                asOfDateTime.toLocalDate();

        LocalTime asOfTime =
                asOfDateTime.toLocalTime();

        // 1. 檢查參數
        if (coachId == null || coachId <= 0) {
            throw new IllegalStateException(
                    "登入教練 ID 不完整"
            );
        }

        if (memberCourseId == null || memberCourseId <= 0) {
            throw new BusinessException(
                    "memberCourseId 必須為正整數"
            );
        }

        if (page == null || page < 1) {
            throw new BusinessException(
                    "page 必須為大於或等於 1 的整數"
            );
        }

        if (size == null || size != PAGE_SIZE) {
            throw new BusinessException(
                    "size 固定為 5"
            );
        }

        // 2. 查方案並確認教練權限
        MemberCourse plan = memberCourseRepo
                .findOverviewById(memberCourseId)
                .orElseThrow(
                        () -> new ResourceNotFoundException(
                                "找不到指定方案"
                        )
                );

        if (!Objects.equals(
                plan.getCoach().getCoachid(),
                coachId
        )) {
            throw new ForbiddenException(
                    "無權查看其他教練方案的 InBody 紀錄"
            );
        }

        // 停用會員仍可查詢歷史量測
        // 記錄被 B2 排除的歷史資料，供後續修正流程追查
        List<InBodyRecordRepo.InBodyAnomaly> anomalies =
                inBodyRecordRepo.findPlanInBodyAnomalies(
                        memberCourseId,
                        asOfDate,
                        asOfTime
                );

        for (InBodyRecordRepo.InBodyAnomaly anomaly : anomalies) {
            log.warn(
                    "B2 排除量測：memberCourseId={}, inBodyId={}, "
                            + "attendanceId={}, reasons={}",
                    memberCourseId,
                    anomaly.getInBodyId(),
                    anomaly.getAttendanceId(),
                    anomaly.getReasons()
            );
        }


        // 3. 先查表格第一頁，取得總筆數及總頁數
        Page<InBodyRecordRepo.InBodyRow> firstPage =
                inBodyRecordRepo.findPlanInBodyPage(
                        memberCourseId,
                        asOfDate,
                        asOfTime,
                        PageRequest.of(0, PAGE_SIZE)
                );

        long totalElements =
                firstPage.getTotalElements();

        int totalPages =
                firstPage.getTotalPages();

        int actualPage = totalPages == 0
                ? 1
                : Math.min(page, totalPages);

        // 4. 取得實際回傳頁面
        Page<InBodyRecordRepo.InBodyRow> selectedPage;

        if (actualPage == 1) {
            selectedPage = firstPage;
        } else {
            selectedPage =
                    inBodyRecordRepo.findPlanInBodyPage(
                            memberCourseId,
                            asOfDate,
                            asOfTime,
                            PageRequest.of(
                                    actualPage - 1,
                                    PAGE_SIZE
                            )
                    );
        }

        // 5. 最新摘要：只取最新一筆有日期的有效量測
        List<InBodyRecordRepo.InBodyRow> latestRows =
                inBodyRecordRepo.findDatedPlanInBody(
                        memberCourseId,
                        asOfDate,
                        asOfTime,
                        "ALL",
                        PageRequest.of(0, 1)
                );

        InBodyPageResponse.RecordItem latestRecord =
                latestRows.isEmpty()
                        ? null
                        : toRecordItem(latestRows.get(0));

        // 6. 三個指標各自查最近 6 筆非空數值
        InBodyPageResponse.Trends trends =
                new InBodyPageResponse.Trends();

        trends.setWeight(
                loadTrend(
                        memberCourseId,
                        asOfDate,
                        asOfTime,
                        "WEIGHT"
                )
        );

        trends.setBodyFatPct(
                loadTrend(
                        memberCourseId,
                        asOfDate,
                        asOfTime,
                        "BODY_FAT"
                )
        );

        trends.setMuscleMass(
                loadTrend(
                        memberCourseId,
                        asOfDate,
                        asOfTime,
                        "MUSCLE_MASS"
                )
        );

        // 7. 組成分頁資訊
        InBodyPageResponse.PageInfo pageInfo =
                new InBodyPageResponse.PageInfo();

        pageInfo.setNumber(actualPage);
        pageInfo.setSize(PAGE_SIZE);
        pageInfo.setTotalElements(totalElements);
        pageInfo.setTotalPages(totalPages);
        pageInfo.setHasPrevious(actualPage > 1);
        pageInfo.setHasNext(actualPage < totalPages);

        // 8. 組成完整回應
        InBodyPageResponse response =
                new InBodyPageResponse();

        response.setMemberCourseId(memberCourseId);
        response.setAsOfDateTime(asOfDateTime);
        response.setLatestRecord(latestRecord);
        response.setTrends(trends);

        response.setItems(
                selectedPage.getContent()
                        .stream()
                        .map(this::toRecordItem)
                        .toList()
        );

        response.setPage(pageInfo);

        return response;
    }

    // 查最近 6 筆，再反轉成時間由舊到新，供趨勢圖使用
    private List<InBodyPageResponse.TrendPoint> loadTrend(
            Integer memberCourseId,
            LocalDate asOfDate,
            LocalTime asOfTime,
            String metric
    ) {
        List<InBodyRecordRepo.InBodyRow> rows =
                inBodyRecordRepo.findDatedPlanInBody(
                        memberCourseId,
                        asOfDate,
                        asOfTime,
                        metric,
                        PageRequest.of(0, TREND_LIMIT)
                );

        List<InBodyPageResponse.TrendPoint> points =
                new ArrayList<>();

        for (InBodyRecordRepo.InBodyRow row : rows) {
            BigDecimal value = switch (metric) {
                case "WEIGHT" -> row.getWeight();
                case "BODY_FAT" -> row.getBodyFatPct();
                case "MUSCLE_MASS" -> row.getMuscleMass();

                default -> throw new IllegalStateException(
                        "未知 InBody 指標：" + metric
                );
            };

            // Repository 應已排除空日期與該指標空值
            if (row.getRecordDate() == null || value == null) {
                throw new IllegalStateException(
                        "InBody 趨勢查詢結果不完整"
                );
            }

            InBodyPageResponse.TrendPoint point =
                    new InBodyPageResponse.TrendPoint();

            point.setInBodyId(row.getInBodyId());
            point.setAttendanceId(row.getAttendanceId());
            point.setRecordDate(row.getRecordDate());

            point.setClassStartDateTime(
                    classStartDateTime(row)
            );

            point.setValue(value);

            points.add(point);
        }

        Collections.reverse(points);

        return points;
    }

    // 表格與最新摘要共用的單筆格式
    private InBodyPageResponse.RecordItem toRecordItem(
            InBodyRecordRepo.InBodyRow row
    ) {
        InBodyPageResponse.RecordItem item =
                new InBodyPageResponse.RecordItem();

        item.setInBodyId(row.getInBodyId());
        item.setAttendanceId(row.getAttendanceId());
        item.setRecordDate(row.getRecordDate());

        item.setClassStartDateTime(
                classStartDateTime(row)
        );

        // 保留同一筆的三個原始數值，不跨紀錄補值
        item.setWeight(row.getWeight());
        item.setBodyFatPct(row.getBodyFatPct());
        item.setMuscleMass(row.getMuscleMass());

        return item;
    }

    private LocalDateTime classStartDateTime(
            InBodyRecordRepo.InBodyRow row
    ) {
        if (row.getClassDate() == null
                || row.getClassStartTime() == null) {
            throw new IllegalStateException(
                    "InBody 對應排課的開始時間不完整"
            );
        }

        return LocalDateTime.of(
                row.getClassDate(),
                row.getClassStartTime()
        );
    }
}