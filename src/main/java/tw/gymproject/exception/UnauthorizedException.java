package tw.gymproject.exception;

//用途：尚未登入或登入已失效
public class UnauthorizedException extends RuntimeException {

    public UnauthorizedException(String message) {
        super(message);
    }
}