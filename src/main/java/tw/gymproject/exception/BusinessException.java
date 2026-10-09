package tw.gymproject.exception;

//用途：資料存在，但這個操作不符合業務規則。
public class BusinessException extends RuntimeException {
    public BusinessException(String message) {
        super(message);
    }
}