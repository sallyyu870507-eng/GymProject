package tw.gymproject.exception;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import jakarta.persistence.EntityNotFoundException;

@RestControllerAdvice
public class GlobalExceptionHandler {
	
	
	// 攔截 Service 刪除寫的 EntityNotFoundException (找不到資料)
    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleEntityNotFound(EntityNotFoundException ex) {
        // 回傳 HTTP 404 Not Found 狀態碼，並把 "找不到該帳號" 的訊息傳給前端
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(Map.of(
                    "success", false,
                    "message", ex.getMessage()
                ));
    }

    // 攔截參數不合法或商業邏輯違反的例外
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex) {
        // 回傳 HTTP 400 Bad Request
        return ResponseEntity.badRequest()
                .body(Map.of(
                        "success", false,
                        "message", ex.getMessage()
                    ));
    }
    //停用已停用的會員回傳HTTP 400 Bad Request
    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, Object>> handleIIllegalState(IllegalStateException ex) {
    	return ResponseEntity.badRequest()
    			.body(Map.of(
    					"success", false,
    					"message", ex.getMessage()
    					));
    }
    //找不到資源的例外處理404
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<Map<String, Object>> handleResourceNotFound(
            NoResourceFoundException ex) {

        return ResponseEntity
        		.status(HttpStatus.NOT_FOUND)
                .body(Map.of(
                    "success", false,
                    "message", "找不到指定的資源"
                ));
    }
    //404找不到要編輯的會員
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handleStatusException(
    		ResponseStatusException ex) {
    	
    	return ResponseEntity
    			.status(HttpStatus.NOT_FOUND)
    			.body(Map.of(
    					"success", false,
    					"message", ex.getMessage()
    					));
    }
    //400，DTO驗證用
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
          //回傳400 badrequest
          return ResponseEntity
        	        .badRequest()
        	        .body(Map.of(
        	            "success", false,
        	            "errors", errors
        	        ));
    	}

    //來自Service帳號重複的例外409
    @ExceptionHandler(DuplicateUsernameException.class)
    public ResponseEntity<Map<String, Object>> handleDuplicate(
            DuplicateUsernameException e) {

        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(Map.of(
                    "success", false,
                    "message", e.getMessage()  //這邊就會收到從service那邊填的拋出例外訊息內容
                ));
    }
    
    // 攔截其他所有沒預期到的系統錯誤 (例如資料庫斷線、空指標等)
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleAllException(Exception ex) {
    	System.out.println("===== 進入我的 ExceptionHandler =====");

       ex.printStackTrace(); //紀錄log
        // 回傳 HTTP 500 Internal Server Error，並隱藏內部細節避免資安漏洞
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        					.body(Map.of(
        							"success", false,
        							"message", "系統發生錯誤請稍後再試。"));
    }
	

}
