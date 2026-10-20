package tw.gymproject.interceptor;

import org.hibernate.internal.build.AllowSysOut;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import tw.gymproject.dto.LoginResultDTO;

@Component
public class LoginInterceptor implements HandlerInterceptor {	
	//寫一個看守人在進入網址前統一先查
	
	private String getHomeByRole(String role) {
//依據登入的role決定 送他回去他自己的版面
	    switch (role) {

	        case "admin":
	            return "/admin";

	        case "coach":
	            return "/coach";

	        case "member":
	            return "/member";

	        default:
	            return "/login.html";
	    }
	}
	
	@Override
	public boolean preHandle(HttpServletRequest request,
			HttpServletResponse response,
			Object handler)
			throws Exception {
		System.out.println("--------開始執行interceptor");
		HttpSession session = request.getSession(false);//有就給我, 沒有就null
		
		LoginResultDTO user = null ;
		//先看session是不是空
		if(session!=null) {
			//不空才取值，否則會有對空 取值得例外發生
			user = (LoginResultDTO) session.getAttribute("user");
		}
		
		String uri = request.getRequestURI(); //得到送請求進來的識別也就是8080/後面的
		if(user==null) {
			if (uri.startsWith("/api/")) {
		        // API 請求：回傳 401 給 JavaScript讓前端去轉畫面
				response.setStatus(
			            HttpServletResponse.SC_UNAUTHORIZED
			        );  //401
		        response.setContentType("application/json;charset=UTF-8");

//		        response.getWriter().write(
//		            "{\"success\":false,\"message\":\"登入已過期，請重新登入\"}"
//		        );

		    } else {
		        // HTML 請求：直接導向登入頁面
		        response.sendRedirect("/login");
		    }

            return false; //停止請求繼續
		}	
		String role = user.getRole();
		
		 System.out.println("URI = " + uri);
		 System.out.println("ROLE = " + role); //除錯查看
		 
//預防有人登入後直接改網址想進入他人的頁面，已實作導回自己角色的頁面		 
		if((uri.startsWith("/admin") || uri.startsWith("/api/admin")) && !"admin".equals(role)) {//判斷有沒有權限進入這些頁面
			if (uri.startsWith("/api/")) { //沒有權限，看他是想跑去API還是jtml頁面，若想進入API就顯示權限不足，若想進頁面就送回自己的角色頁面
		        response.sendError(
		                HttpServletResponse.SC_FORBIDDEN);} //拋出沒有權限的代碼403給前端，讓前端用Fetch接到之後做前端顯示
			else {response.sendRedirect(getHomeByRole(role));}//送回角色該去的頁面
			return false;
		}
		if((uri.startsWith("/coach") || uri.startsWith("/api/coach")) && !"coach".equals(role) ) {
			if (uri.startsWith("/api/")) { //資料接口
		        response.sendError(
		                HttpServletResponse.SC_FORBIDDEN);}//拋出沒有權限的代碼給前端，讓前端用Fetch接到之後做前端顯示
			else {response.sendRedirect(getHomeByRole(role));}
			return false;
		}
		if((uri.startsWith("/member") || uri.startsWith("/api/member")) && !"member".equals(role) ) {
			if (uri.startsWith("/api/")) { //資料接口
		        response.sendError(
		                HttpServletResponse.SC_FORBIDDEN);}
			else{response.sendRedirect(getHomeByRole(role));}
			return false;
		}
		return true;
	}

}
