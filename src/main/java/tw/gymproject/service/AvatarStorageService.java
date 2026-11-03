package tw.gymproject.service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

/**
 * 會員照片存檔：放在 {app.upload-dir}/avatars/ 底下，網址是 /uploads/avatars/檔名。
 * app.upload-dir 沒設定時用專案資料夾裡的 uploads/（啟動的工作目錄）。
 */
@Service
public class AvatarStorageService {

    /** 只接受這幾種圖片，副檔名由內容類型決定，不相信使用者給的檔名 */
    private static final Map<String, String> EXT = Map.of(
            "image/jpeg", "jpg",
            "image/png", "png",
            "image/webp", "webp");

    public static final long MAX_BYTES = 1024 * 1024; // 1 MB（和 Spring Boot 預設的上傳上限一樣）
    public static final String URL_PREFIX = "/uploads/avatars/";

    private final Path dir;

    public AvatarStorageService(@Value("${app.upload-dir:uploads}") String uploadDir) {
        this.dir = Path.of(uploadDir, "avatars").toAbsolutePath().normalize();
    }

    /** 存檔並回傳網址，例如 /uploads/avatars/member-1-1730600000000.jpg */
    public String save(Integer memberid, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "請選擇一張照片");
        }
        if (file.getSize() > MAX_BYTES) {
            throw new ResponseStatusException(HttpStatus.PAYLOAD_TOO_LARGE, "照片不能超過 1 MB");
        }
        String ext = EXT.get(String.valueOf(file.getContentType()).toLowerCase());
        if (ext == null) {
            throw new ResponseStatusException(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "只接受 JPG、PNG 或 WebP 圖片");
        }

        String filename = "member-" + memberid + "-" + System.currentTimeMillis() + "." + ext;
        try (InputStream in = file.getInputStream()) {
            Files.createDirectories(dir);
            Files.copy(in, dir.resolve(filename), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "照片存檔失敗", e);
        }
        return URL_PREFIX + filename;
    }

    /** 刪掉舊照片；只刪這個資料夾裡、由這個服務存的檔案 */
    public void deleteIfOwned(String url) {
        if (url == null || !url.startsWith(URL_PREFIX)) {
            return;
        }
        Path target = dir.resolve(url.substring(URL_PREFIX.length())).normalize();
        if (!target.startsWith(dir)) {
            return;
        }
        try {
            Files.deleteIfExists(target);
        } catch (IOException ignored) {
            // 舊檔刪不掉不影響這次上傳
        }
    }

    public Path getDir() {
        return dir;
    }
}
