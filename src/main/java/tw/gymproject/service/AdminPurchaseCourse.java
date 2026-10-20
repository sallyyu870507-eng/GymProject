package tw.gymproject.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import tw.gymproject.dto.AdminPurchaseReqDTO;
import tw.gymproject.dto.PurchaseCoachDTO;
import tw.gymproject.dto.PurchaseCourseDTO;
import tw.gymproject.entity.Coach;
import tw.gymproject.entity.CoachCourseId;
import tw.gymproject.entity.Course;
import tw.gymproject.entity.Member;
import tw.gymproject.entity.Membercourse;
import tw.gymproject.repository.AdminMemberCourseRepo;
import tw.gymproject.repository.CoachCourseRepo;
import tw.gymproject.repository.CoachRepository;
import tw.gymproject.repository.CourseRepo;
import tw.gymproject.repository.MemberRepository;
@Service
@RequiredArgsConstructor  //使用lombok的建構子注入，就不用自己寫建構式
public class AdminPurchaseCourse {
	//先固定方案為十堂
	private static final int PURCHASE_SESSIONS = 10;

	private final AdminMemberCourseRepo adminCourseRepo; //管理員端的MemberCourse，使用最上面lombok的建構子注入
    private final MemberRepository memberRepository;
    private final CoachRepository coachRepository;
    private final CourseRepo courseRepository;
    private final CoachCourseRepo coachCourseRepository;
	
    //先顯示目前active的課程
    @Transactional(readOnly = true)
    public List<PurchaseCourseDTO> getAvailableCourses() {
   
        List<Course> courses =
                courseRepository.findByStatusOrderByCoursenameAsc("active");

        List<PurchaseCourseDTO> result = new ArrayList<>();

        for (Course course : courses) {

            PurchaseCourseDTO dto = new PurchaseCourseDTO(
                    course.getCourseid(),
                    course.getCoursename(),
                    course.getPrice()
            );

            result.add(dto);
        }

        return result;
    }
    
    //選了課程之後顯示課程底下有哪些教練
    @Transactional(readOnly = true)
    public List<PurchaseCoachDTO> getAvailableCoaches(
            Integer courseid) {
  
        // 1. 確認課程存在
        Course course = courseRepository.findById(courseid)
                .orElseThrow(() ->
                    new EntityNotFoundException("找不到該課程"));
//  	System.out.println("查詢課程 ID：" + course.getCourseid());
//    	System.out.println("課程名稱：" + course.getCoursename());
//    	System.out.println("課程狀態：[" + course.getStatus() + "]");
        // 2. 確認課程是否啟用
        if (!"active".equals(course.getStatus().trim())) {
            throw new IllegalArgumentException("此課程已停用");
        }

        // 3. 用courseId去查詢有教授這門課的教練
        List<Coach> coaches =
                coachCourseRepository.findCoachesByCourseId(courseid);

        // 4. 將 Entity 轉成 DTO
        List<PurchaseCoachDTO> result = new ArrayList<>();
        //列出教練
        for (Coach coach : coaches) {

            PurchaseCoachDTO dto = new PurchaseCoachDTO(
                    coach.getCoachid(),
                    coach.getCoachno(),
                    coach.getName()
            );

            result.add(dto);
        }

        return result;
    }
    
    
	@Transactional
	public Integer createPurchase(
	        Integer memberid,
	        AdminPurchaseReqDTO dto) { //包含coachid以及courseid
		
	    // 確認各種條件是否正確(會員、教練、課程及授課關聯)
		// 1. 確認會員存在
        Member member = memberRepository.findById(memberid)
                .orElseThrow(() ->
                    new EntityNotFoundException("找不到該會員"));

        // 確認會員是否啟用
        if (!"active".equals(member.getStatus().trim())) {
            throw new IllegalArgumentException("此會員已停用，無法購課");
        }

        // 確認會員的登入帳號是否啟用
        if (member.getAccount() == null
                || !"active".equals(member.getAccount().getStatus().trim())) {

            throw new IllegalArgumentException("會員帳號未啟用，無法購課");
        }


        // 2. 確認教練存在
        Coach coach = coachRepository.findById(dto.getCoachid())
                .orElseThrow(() ->
                    new EntityNotFoundException("找不到該教練"));

        // 確認教練是否啟用
        if (!"active".equals(coach.getStatus().trim())) {
            throw new IllegalArgumentException("此教練已停用");
        }
        
        //教練的帳號若未啟用無法登入

        // ===== 3. 確認課程存在 =====
        Course course = courseRepository.findById(dto.getCourseid())
                .orElseThrow(() ->
                    new EntityNotFoundException("找不到該課程"));

        // 確認課程是否啟用
        if (!"active".equals(course.getStatus().trim())) {
            throw new IllegalArgumentException("此課程已停用");
        }

        //!重點
        // ===== 4. 驗證教練是否有教授此課程 =====
        //以免有人透過網址更改購買內容，要確認資料庫有沒有教練與課程的關係
        CoachCourseId coachCourseId = new CoachCourseId(
                dto.getCoachid(),
                dto.getCourseid()
        );
        boolean exists = coachCourseRepository.existsById(coachCourseId);

        if (!exists) {
            throw new IllegalArgumentException(
                    "此教練沒有教授所選擇的課程");
        }
        // ===== 5. 驗證課程價格 =====

        BigDecimal purchasePrice = course.getPrice();
        //若為非負整數
        if (purchasePrice == null
                || purchasePrice.signum() < 0) {

            throw new IllegalArgumentException("課程價格設定錯誤");
        }
//視運作需求是否保留購買課程當下的價格totalamount
//以免未來調整course.price的話連同過往紀錄一起更改造成紀錄不符
//        取得單堂價格
//        BigDecimal unitPrice = course.getPrice();
//        目前專案設定方案固定為十堂
//        BigDecimal是物件無法直接用*做運算，multiply是官方的乘法
//        BigDecimal.valueOf()則是將數值轉換成BigDecimal
//        BigDecimal totalAmount = unitPrice.multiply(
//            BigDecimal.valueOf(PURCHASE_SESSIONS)
//        );
        
        

        // ===== 最後建立購課紀錄 =====
        //以上條件都通過才建立購課
        Membercourse purchase = new Membercourse();

        purchase.setMember(member);
        purchase.setCoach(coach);
        purchase.setCourse(course);
        //固定方案為十堂
        purchase.setTotalsessions(PURCHASE_SESSIONS);
        purchase.setRemainingsessions(PURCHASE_SESSIONS);

//      purchase.setTotalamount(totalAmount);

        purchase.setPurchasedate(LocalDate.now());
        purchase.setStatus("active");


        // ===== 7. 儲存購課 =====

        Membercourse saved =
        		adminCourseRepo.save(purchase);

        return saved.getMembercourseid();
    }
}


