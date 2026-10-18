package tw.gymproject.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import tw.gymproject.interceptor.LoginInterceptor;

@Configuration
//設定區   哪些網址需要經過interceptor檢查
public class WebConfig implements WebMvcConfigurer {

	//把interceptor帶入備用
	
	private final LoginInterceptor loginInterceptor;
	
	public WebConfig(LoginInterceptor loginInterceptor) {
	    this.loginInterceptor = loginInterceptor;
	}
	@Override
	public void addInterceptors(InterceptorRegistry registry) { //把網址註冊進來
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
                "/member.html",
                "/api/attendance/**"
        );
	}
}
