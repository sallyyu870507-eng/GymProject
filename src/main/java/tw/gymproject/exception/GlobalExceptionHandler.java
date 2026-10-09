package tw.gymproject.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

/*
400 BusinessException
400 Request / JSON 格式錯誤
403 ForbiddenException
404 ResourceNotFoundException
409 ConflictException
500 Exception
*/
@RestControllerAdvice
public class GlobalExceptionHandler {


    // =========================================================
    // 400:業務規則錯誤
    // 例如：
    // status = HELLO
    // InBody 資料不完整
    // InBody 數值不合法
    // 新增堂數 <= 0
    // =========================================================
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Map<String, Object>>
    handleBusinessException(
            BusinessException ex
    ) {

        Map<String, Object> body =
                new LinkedHashMap<>();

        body.put(
                "timestamp",
                LocalDateTime.now()
        );

        body.put(
                "status",
                HttpStatus.BAD_REQUEST.value()
        );

        body.put(
                "error",
                "Bad Request"
        );

        body.put(
                "message",
                ex.getMessage()
        );

        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(body);
    }


    // =========================================================
    // 400:Request 參數 / JSON 格式錯誤
    // 例如：
    // ?date=abc
    // JSON 格式寫壞
    // date 參數沒有傳
    // =========================================================
    @ExceptionHandler({
            MethodArgumentTypeMismatchException.class,
            HttpMessageNotReadableException.class,
            MissingServletRequestParameterException.class
    })
    public ResponseEntity<Map<String, Object>>
    handleBadRequest(
            Exception ex
    ) {

        Map<String, Object> body =
                new LinkedHashMap<>();

        body.put(
                "timestamp",
                LocalDateTime.now()
        );

        body.put(
                "status",
                HttpStatus.BAD_REQUEST.value()
        );

        body.put(
                "error",
                "Bad Request"
        );

        body.put(
                "message",
                "請求參數或 JSON 格式錯誤"
        );

        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(body);
    }


    // =========================================================
    // 403:沒有操作權限
    // 例如：
    // coach 1 想查看 / 修改 coach 2 的學員
    // 403 Forbidden
    // ✅ 程式邏輯已完成
    // ⏳ 目前 DB 無 coachId ≠ 1 的資料，尚未實測
    // =========================================================
    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<Map<String, Object>>
    handleForbidden(
            ForbiddenException ex
    ) {

        Map<String, Object> body =
                new LinkedHashMap<>();

        body.put(
                "timestamp",
                LocalDateTime.now()
        );

        body.put(
                "status",
                HttpStatus.FORBIDDEN.value()
        );

        body.put(
                "error",
                "Forbidden"
        );

        body.put(
                "message",
                ex.getMessage()
        );

        return ResponseEntity
                .status(HttpStatus.FORBIDDEN)
                .body(body);
    }


    // =========================================================
    // 404:查不到資料
    // 例如：
    // Booking ID 不存在
    // MemberCourse ID 不存在
    // =========================================================
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, Object>>
    handleResourceNotFound(
            ResourceNotFoundException ex
    ) {

        Map<String, Object> body =
                new LinkedHashMap<>();

        body.put(
                "timestamp",
                LocalDateTime.now()
        );

        body.put(
                "status",
                HttpStatus.NOT_FOUND.value()
        );

        body.put(
                "error",
                "Not Found"
        );

        body.put(
                "message",
                ex.getMessage()
        );

        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(body);
    }

    // =========================================================
    // 409:目前資料狀態與請求衝突
    // 例如：
    // 已取消 Booking 不能更新出席
    // 剩餘堂數不足
    // 未來若有並行更新衝突，也可以放這裡
    // =========================================================
    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<Map<String, Object>>
    handleConflict(
            ConflictException ex
    ) {

        Map<String, Object> body =
                new LinkedHashMap<>();

        body.put(
                "timestamp",
                LocalDateTime.now()
        );

        body.put(
                "status",
                HttpStatus.CONFLICT.value()
        );

        body.put(
                "error",
                "Conflict"
        );

        body.put(
                "message",
                ex.getMessage()
        );

        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(body);
    }


    // =========================================================
    // 500:真正沒有預期到的系統錯誤
    // 前面都沒有接住，才會進到這裡
    // =========================================================
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>>
    handleException(
            Exception ex
    ) {

        Map<String, Object> body =
                new LinkedHashMap<>();

        body.put(
                "timestamp",
                LocalDateTime.now()
        );

        body.put(
                "status",
                HttpStatus.INTERNAL_SERVER_ERROR.value()
        );

        body.put(
                "error",
                "Internal Server Error"
        );

        body.put(
                "message",
                "系統發生未預期錯誤"
        );

        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(body);
    }
}