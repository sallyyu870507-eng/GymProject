package tw.gymproject.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.TransactionException;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.transaction.support.TransactionTemplate;

import tw.gymproject.exception.BusinessException;
import tw.gymproject.exception.ConflictException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Supplier;
import java.util.regex.Pattern;



/*
這隻是 F2、P2 共用的短期提交保護：
- 同編號、同內容：回傳原成功結果。
- 同編號、不同內容：回 409。
- 同一次提交正在處理：回 409。
- 成功結果保留 30 分鐘，最多 1,000 筆。
- 資料庫交易成功後，才記住成功結果。
- 每次請求都先重新檢查方案授權。
 */
@Service
public class SubmissionGuardService {

    // 已完成結果保留 30 分鐘。
    private static final long RETENTION_NANOS =
            Duration.ofMinutes(30).toNanos();

    // 包含處理中、已完成及結果不明的提交。
    private static final int MAX_ENTRIES = 1000;

    private static final Pattern UUID_PATTERN = Pattern.compile(
            "^[0-9a-fA-F]{8}-"
                    + "[0-9a-fA-F]{4}-"
                    + "[0-9a-fA-F]{4}-"
                    + "[0-9a-fA-F]{4}-"
                    + "[0-9a-fA-F]{12}$"
    );

    private final ObjectMapper objectMapper;
    private final TransactionTemplate transactionTemplate;

    private final Object monitor = new Object();

    private final Map<SubmissionKey, Entry> entries =
            new HashMap<>();

    public SubmissionGuardService(
            ObjectMapper objectMapper,
            PlatformTransactionManager transactionManager
    ) {
        this.objectMapper = objectMapper;

        this.transactionTemplate =
                new TransactionTemplate(transactionManager);

        this.transactionTemplate.setPropagationBehavior(
                TransactionDefinition.PROPAGATION_REQUIRED
        );
    }

    /**
     * 執行一次受到短期提交保護的新增操作。
     *
     * accountId：
     *   必須取自後端登入資料，不能相信 Body 傳入的帳號。
     *
     * requestPath：
     *   由後端依已驗證的 ID 組合標準路徑。
     *
     * normalizedRequest：
     *   呼叫端先驗證並正規化後的請求資料。
     *   不可放入每次都不同的現在時間或隨機值。
     *
     * authorizationCheck：
     *   每次都執行的方案存在與教練權限檢查。
     *   只查詢，不新增或修改資料。
     *
     * operation：
     *   真正的新增操作，回傳要保存的 Response DTO。
     *   業務新增與結果 JSON 序列化會放在同一個交易內。
     */
    public SubmissionResult execute(
            Integer accountId,
            String requestPath,
            String idempotencyKey,
            Object normalizedRequest,
            Runnable authorizationCheck,
            Supplier<?> operation
    ) {
        if (accountId == null || accountId <= 0) {
            throw new IllegalArgumentException(
                    "提交保護必須使用有效的登入帳號"
            );
        }

        if (requestPath == null
                || !requestPath.startsWith("/api/")) {
            throw new IllegalArgumentException(
                    "提交保護必須使用後端組合的 API 路徑"
            );
        }

        Objects.requireNonNull(
                normalizedRequest,
                "normalizedRequest 不可為 null"
        );

        Objects.requireNonNull(
                authorizationCheck,
                "authorizationCheck 不可為 null"
        );

        Objects.requireNonNull(
                operation,
                "operation 不可為 null"
        );

        /*
         * 這裡必須掌握真正的交易提交時間。
         * 呼叫端不可先開啟外層交易，否則此處返回時，
         * 外層交易可能尚未提交。
         */
        if (TransactionSynchronizationManager
                .isActualTransactionActive()) {
            throw new IllegalStateException(
                    "請在沒有外層交易的方法中呼叫提交保護"
            );
        }

        /*
         * 即使是重送，也必須先重新確認方案授權。
         * 未授權者不能取得快取中的成功結果。
         */
        authorizationCheck.run();

        UUID submissionId = parseKey(idempotencyKey);

        String requestHash = hashRequest(normalizedRequest);

        SubmissionKey key = new SubmissionKey(
                accountId,
                "POST",
                requestPath,
                submissionId
        );

        Entry newEntry;

        synchronized (monitor) {
            removeExpiredEntries();

            Entry existing = entries.get(key);

            if (existing != null) {
                if (!existing.requestHash.equals(requestHash)) {
                    throw new ConflictException(
                            "此提交編號已用於不同內容，"
                                    + "請使用新的提交編號"
                    );
                }

                if (existing.state == State.COMPLETED) {
                    return existing.result;
                }

                if (existing.state == State.UNKNOWN) {
                    throw new ConflictException(
                            "上次提交結果尚未確認，"
                                    + "請先查詢紀錄，勿直接重新新增"
                    );
                }

                throw new ConflictException(
                        "此提交仍在處理中，"
                                + "請稍後使用相同提交編號重試"
                );
            }

            /*
             * 不提早淘汰仍在保留期限內的成功紀錄。
             * 否則可能讓原本受保護的提交再次新增。
             */
            if (entries.size() >= MAX_ENTRIES) {
                throw new ConflictException(
                        "目前提交保護容量已滿，"
                                + "尚未執行新增，請稍後再試"
                );
            }

            newEntry = new Entry(requestHash);
            entries.put(key, newEntry);
        }

        SubmissionResult result;

        try {
            result = transactionTemplate.execute(
                    transactionStatus -> {
                        /*
                         * 在新增交易內再確認一次權限。
                         * operation 仍須自行檢查其業務規則。
                         */
                        authorizationCheck.run();

                        Object response = operation.get();

                        if (response == null) {
                            throw new IllegalStateException(
                                    "新增操作沒有回傳成功結果"
                            );
                        }

                        /*
                         * 先在交易內完成序列化。
                         * 若序列化失敗，業務新增一起回滾。
                         */
                        return new SubmissionResult(
                                201,
                                toJson(response)
                        );
                    }
            );

            if (result == null) {
                throw new IllegalStateException(
                        "交易沒有回傳提交結果"
                );
            }

        } catch (TransactionException ex) {
            /*
             * 交易管理或提交階段發生錯誤時，
             * 保守視為結果不明，避免直接重跑造成重複。
             */
            synchronized (monitor) {
                newEntry.state = State.UNKNOWN;
                newEntry.finishedAtNanos = System.nanoTime();
            }

            throw ex;

        } catch (RuntimeException | Error ex) {
            /*
             * 業務驗證或新增過程拋出錯誤，
             * TransactionTemplate 已完成回滾後才會到這裡。
             * 移除本次占位，沒有保存假的成功結果。
             */
            synchronized (monitor) {
                entries.remove(key, newEntry);
            }

            throw ex;
        }

        /*
         * TransactionTemplate 正常返回，
         * 代表這筆交易已成功提交。
         */
        synchronized (monitor) {
            newEntry.result = result;
            newEntry.finishedAtNanos = System.nanoTime();
            newEntry.state = State.COMPLETED;
        }

        return result;
    }

    private UUID parseKey(String value) {
        if (value == null || value.isBlank()) {
            throw new BusinessException(
                    "Idempotency-Key 為必填"
            );
        }

        if (!UUID_PATTERN.matcher(value).matches()) {
            throw new BusinessException(
                    "Idempotency-Key 必須為 UUID 格式"
            );
        }

        return UUID.fromString(value);
    }

    private String hashRequest(Object normalizedRequest) {
        String json = toJson(normalizedRequest);

        try {
            byte[] hash = MessageDigest
                    .getInstance("SHA-256")
                    .digest(
                            json.getBytes(StandardCharsets.UTF_8)
                    );

            return java.util.HexFormat
                    .of()
                    .formatHex(hash);

        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(
                    "無法建立提交內容摘要",
                    ex
            );
        }
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);

        } catch (JsonProcessingException ex) {
            throw new IllegalStateException(
                    "無法轉換提交資料或成功結果",
                    ex
            );
        }
    }

    /*
     * 僅在 monitor 鎖定期間呼叫。
     *
     * 處理中的提交不因時間到期而移除，
     * 避免舊操作尚未結束，新操作又開始執行。
     */
    private void removeExpiredEntries() {
        long now = System.nanoTime();

        entries.entrySet().removeIf(
                item -> {
                    Entry entry = item.getValue();

                    return entry.state != State.PROCESSING
                            && now - entry.finishedAtNanos
                            >= RETENTION_NANOS;
                }
        );
    }

    /**
     * HTTP 狀態碼與原始成功 JSON。
     * 使用不可變字串，避免回傳後被修改。
     */
    public record SubmissionResult(
            int statusCode,
            String responseJson
    ) {
    }

    private record SubmissionKey(
            Integer accountId,
            String httpMethod,
            String requestPath,
            UUID idempotencyKey
    ) {
    }

    private enum State {
        PROCESSING,
        COMPLETED,
        UNKNOWN
    }

    private static final class Entry {

        private final String requestHash;

        private State state = State.PROCESSING;

        private SubmissionResult result;

        private long finishedAtNanos;

        private Entry(String requestHash) {
            this.requestHash = requestHash;
        }
    }
}