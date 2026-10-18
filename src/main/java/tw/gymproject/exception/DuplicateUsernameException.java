package tw.gymproject.exception;

public class DuplicateUsernameException extends RuntimeException {

    public DuplicateUsernameException(String message) {
        super(message);  //把訊息傳給父類別就可以透過e.getMessage()取得訊息
    }
}
