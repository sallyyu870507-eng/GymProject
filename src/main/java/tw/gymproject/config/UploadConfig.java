package tw.gymproject.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import tw.gymproject.service.AvatarStorageService;

/**
 * 讓上傳的照片可以用網址看到：/uploads/avatars/xxx.jpg → {app.upload-dir}/avatars/xxx.jpg
 */
@Configuration
public class UploadConfig implements WebMvcConfigurer {

    private final AvatarStorageService avatarStorage;

    public UploadConfig(AvatarStorageService avatarStorage) {
        this.avatarStorage = avatarStorage;
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler(AvatarStorageService.URL_PREFIX + "**")
                .addResourceLocations(avatarStorage.getDir().toUri().toString());
    }
}
