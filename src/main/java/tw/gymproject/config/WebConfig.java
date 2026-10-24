package tw.gymproject.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import tw.gymproject.interceptor.LoginInterceptor;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final LoginInterceptor loginInterceptor;

    public WebConfig(LoginInterceptor loginInterceptor) {
        this.loginInterceptor = loginInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(loginInterceptor)
                .addPathPatterns(
                        "/api/admin/**",
                        "/admin/**",
                        "/admin",
                        "/api/coach/**",
                        "/coach/**",
                        "/coach",
                        "/member/**",
                        "/member",
                        "/admin.html",
                        "/coach.html",
                        "/member.html"
                );
    }
}
