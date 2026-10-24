package tw.gymproject.exception;

import java.util.LinkedHashMap;
import java.util.Map;

import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler({
            BusinessException.class,
            IllegalArgumentException.class,
            MethodArgumentNotValidException.class,
            MethodArgumentTypeMismatchException.class,
            HttpMessageNotReadableException.class,
            MissingServletRequestParameterException.class,
            ConstraintViolationException.class
    })
    public ResponseEntity<Map<String, Object>> handleBadRequest(Exception ex) {
        String message = ex instanceof MethodArgumentNotValidException validation
                ? validation.getBindingResult().getFieldErrors().stream()
                        .findFirst()
                        .map(error -> error.getDefaultMessage())
                        .orElse("請求資料不正確")
                : ex.getMessage();
        return error(HttpStatus.BAD_REQUEST, "Bad Request", safeMessage(message, "請求資料不正確"));
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<Map<String, Object>> handleUnauthorized(UnauthorizedException ex) {
        return error(HttpStatus.UNAUTHORIZED, "Unauthorized", safeMessage(ex.getMessage(), "尚未登入或登入已失效"));
    }

    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<Map<String, Object>> handleForbidden(ForbiddenException ex) {
        return error(HttpStatus.FORBIDDEN, "Forbidden", safeMessage(ex.getMessage(), "沒有操作權限"));
    }

    @ExceptionHandler({
            ResourceNotFoundException.class,
            EntityNotFoundException.class,
            NoResourceFoundException.class
    })
    public ResponseEntity<Map<String, Object>> handleNotFound(Exception ex) {
        return error(HttpStatus.NOT_FOUND, "Not Found", "找不到指定的資源");
    }

    @ExceptionHandler({ConflictException.class, DuplicateUsernameException.class})
    public ResponseEntity<Map<String, Object>> handleConflict(Exception ex) {
        return error(HttpStatus.CONFLICT, "Conflict", safeMessage(ex.getMessage(), "資料衝突"));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handleResponseStatus(ResponseStatusException ex) {
        HttpStatusCode status = ex.getStatusCode();
        String message = ex.getReason();
        if (status.is5xxServerError()) {
            log.error("Request failed with status {}", status.value(), ex);
            message = "系統發生未預期錯誤";
        }
        return error(status, status.toString(), safeMessage(message, "請求無法完成"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleUnexpected(Exception ex) {
        log.error("Unexpected request failure", ex);
        return error(HttpStatus.INTERNAL_SERVER_ERROR, "Internal Server Error", "系統發生未預期錯誤");
    }

    private ResponseEntity<Map<String, Object>> error(
            HttpStatusCode status,
            String error,
            String message) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("status", status.value());
        body.put("error", error);
        body.put("message", message);
        return ResponseEntity.status(status).body(body);
    }

    private String safeMessage(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
