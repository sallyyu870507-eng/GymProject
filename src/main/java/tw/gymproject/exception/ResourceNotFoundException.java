package tw.gymproject.exception;

//用途:資料庫應該要有這筆資料，但找不到。
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}