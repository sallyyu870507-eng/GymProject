package tw.gymproject.globalException;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import jakarta.persistence.EntityNotFoundException;

@RestControllerAdvice
public class GlobalExceptionHandler {
	
	// 攔截 Service 刪除寫的 EntityNotFoundException (找不到資料)
    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<String> handleEntityNotFound(EntityNotFoundException ex) {
        // 回傳 HTTP 404 Not Found 狀態碼，並把 "找不到該帳號" 的訊息傳給前端
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
    }

    // 攔截參數不合法或商業邏輯違反的例外
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> handleIllegalArgument(IllegalArgumentException ex) {
        // 回傳 HTTP 400 Bad Request
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ex.getMessage());
    }
    //找不到資源的例外處理
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<String> handleResourceNotFound(
            NoResourceFoundException ex) {

        return ResponseEntity
            .status(HttpStatus.NOT_FOUND)
            .body("找不到指定的資源");
    }
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(
            MethodArgumentNotValidException e) {
    	  Map<String, String> errors = new HashMap<>();

          // 2. 取得所有欄位驗證錯誤
          e.getBindingResult()
           .getFieldErrors()
           .forEach(error -> {

               String field = error.getField();
               String message = error.getDefaultMessage();

               errors.putIfAbsent(field, message);
           });

          // 3. 組裝要回傳給前端的 JSON
          Map<String, Object> result = new HashMap<>();

          result.put("success", false);
          result.put("errors", errors);

          // 4. 回傳 HTTP 400
          return ResponseEntity
                  .badRequest()
                  .body(result);
    	   	
    }

    
    // 攔截其他所有沒預期到的系統錯誤 (例如資料庫斷線、空指標等)
    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleAllException(Exception ex) {
       ex.printStackTrace(); //紀錄log
        // 回傳 HTTP 500 Internal Server Error，並隱藏內部細節避免資安漏洞
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("伺服器發生未知錯誤，請稍後再試。");
    }
	

}
