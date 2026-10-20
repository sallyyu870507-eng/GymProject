package tw.gymproject.service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.mindrot.jbcrypt.BCrypt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import tw.gymproject.dto.CoachMemberUpdateDTO;
import tw.gymproject.dto.CoachRegisterDTO;
import tw.gymproject.dto.MemberCourseDTO;
import tw.gymproject.dto.MemberListDTO;
import tw.gymproject.dto.RegisterDTO;
import tw.gymproject.entity.Coach;
import tw.gymproject.entity.Member;
import tw.gymproject.entity.Useraccount;
import tw.gymproject.exception.DuplicateUsernameException;
import tw.gymproject.repository.AccountRepository;
import tw.gymproject.repository.CoachRepository;
import tw.gymproject.repository.MemberRepository;

@Transactional
@Service
public class CoachMemberService {
	
	private final AccountRepository repository ;
	private final MemberRepository memberRepository;
	private final CoachRepository coachRepository;
	
	public CoachMemberService(AccountRepository repository,MemberRepository memberRepository,CoachRepository coachRepository) {
		this.repository=repository;
		this.memberRepository=memberRepository;
		this.coachRepository=coachRepository;
	}
	
	
	//會員清單分頁
	public Map<String, Object> findCoachMembers(int page, 
											int size, 
											Integer coachid,
											String keyword) {  //回傳給Controller
		if (keyword != null) {
		    keyword = keyword.trim();
		}
	//設定當前分頁該顯示的會員的分頁條件
	Pageable pageable = PageRequest.of(page, size);//建立分頁條件

    if (coachid == null) {
        throw new ResponseStatusException(
            HttpStatus.UNAUTHORIZED,
            "尚未取得登入教練資訊"
        );
    }
	Page<Member> members =
			coachRepository.searchCoachMembers(coachid, keyword, pageable);
	
	 //取得當頁所有學員ID，準備給查詢學員課程用
    List<Integer> memberIds = members.getContent()
        .stream()
        .map(Member::getMemberid)
        .toList();
    //把會員id獨立出來，如果沒有會員就傳固定空的陣列
    List<Object[]> rowList = memberIds.isEmpty()
            ? List.of()
            : coachRepository.findMemberCourses(
                    coachid, memberIds);
    //建立 Map 存放每位學員的課程，可能有多筆
    Map<Integer, List<MemberCourseDTO>> courseMap = new HashMap<>();
	//把每筆課程清單做成[]，格式顯示給前端
    for (Object[] row : rowList) {

        Integer memberid = ((Number) row[0]).intValue();
        Integer courseid = ((Number) row[1]).intValue();
        String coursename = (String) row[2];
        Integer remaining = ((Number) row[3]).intValue();

        MemberCourseDTO course = new MemberCourseDTO();
        course.setCourseid(courseid);
        course.setCoursename(coursename);
        course.setRemainingsessions(remaining);
        
        //如果courseMap有key也就是會員id，就把剛組好的course加進去，如果沒有就給他空的List
        courseMap.computeIfAbsent(
            memberid,
            k -> new ArrayList<>()
        ).add(course);
        //把目前這筆課程DTO放入學員的課程清單
    }
    
    //取得當頁所有學員的個人資料+課程資料
	//使用pageable的page.map功能幫忙跑迴圈，能保留分頁資訊
	Page<MemberListDTO> dtoPage = members.map(member -> {

	    MemberListDTO dto = new MemberListDTO();
	    dto.setAccountid(member.getAccount().getAccountid());
		dto.setMemberid(member.getMemberid());
		dto.setMemberno(member.getMemberno());
		dto.setName(member.getName());
		dto.setGender(member.getGender());
		dto.setPhone(member.getPhone());
		dto.setStatus(member.getStatus());
	    // 取得這位學員的所有購課紀錄，找不到就回傳空List
	    dto.setCourses(
	        courseMap.getOrDefault(member.getMemberid(),
	        							new ArrayList<>()
	        )
	    );

	    return dto;
	});
		Map<String, Object> result = new HashMap<>();
	
		result.put("members", dtoPage.getContent());  //前面拚出來的MemberList
		result.put("currentPage", dtoPage.getNumber()); //目前頁碼
		result.put("pageSize", dtoPage.getSize()); //每頁幾筆
		result.put("totalPages", dtoPage.getTotalPages()); //總頁數
		result.put("totalElements", dtoPage.getTotalElements()); //總會員數
		result.put("hasNext", dtoPage.hasNext()); //boolean是否有下一頁
		result.put("hasPrev", dtoPage.hasPrevious()); //boolean是否有上一頁
		
		return result; //交給controller整理給前端
}
	
	//顯示學員舊的編輯資料
	public CoachMemberUpdateDTO getMemberForEdit(
	        Integer memberid,
	        Integer coachid) {

	    // 先驗證教練是否有權查看此學員
	    if (coachRepository.existsCoachMember(
	            memberid, coachid) != 1) { //Repository那邊設定的規則，不等於1代表無關

	        throw new ResponseStatusException(
	            HttpStatus.FORBIDDEN,
	            "沒有權限查看此學員"
	        );
	    }

	    // 取得該學員
	    Member member = memberRepository.findById(memberid)
	        .orElseThrow(() ->
	            new ResponseStatusException(
	                HttpStatus.NOT_FOUND,
	                "找不到會員"
	            )
	        );

	    // 學員舊的資料轉成 DTO
	    CoachMemberUpdateDTO dto = new CoachMemberUpdateDTO();

	    dto.setName(member.getName());
	    dto.setPhone(member.getPhone());
	    dto.setEmail(member.getEmail());

	    return dto;
	}
	
	//儲存更新的會員資料
	public void updateCoachMember(
	        Integer memberid,
	        Integer coachid,
	        CoachMemberUpdateDTO dto) {

	    // 一樣先驗證教練與學員是否有關聯
	    if (coachRepository.existsCoachMember(
	            memberid, coachid) != 1) { //Repository那邊設定的規則，不等於1代表無關

	        throw new ResponseStatusException(
	            HttpStatus.FORBIDDEN,
	            "沒有權限修改此學員"
	        );
	    }

	    // 查詢會員
	    Member member = memberRepository.findById(memberid)
	        .orElseThrow(() ->
	            new ResponseStatusException(
	                HttpStatus.NOT_FOUND,
	                "找不到會員"
	            )
	        );

	    // 更新允許修改的資料
	    member.setName(dto.getName());
	    member.setPhone(dto.getPhone());
	    member.setEmail(dto.getEmail());

	    // @Transactional 交易完成時，
	    // Hibernate Dirty Checking 自動更新資料庫
	}
	
	
	
	
	
	
	
	//註冊教練帳號
	public boolean registerCoach(CoachRegisterDTO coachDTO) {
		
		//檢查帳號是否重複
		if(repository.existsByUsername(coachDTO.getUsername())) {
					throw new DuplicateUsernameException(
							"帳號已存在，請更換其他名稱");}//也有可能停用，洽館員
			
			Useraccount account = new Useraccount();
			account.setUsername(coachDTO.getUsername());
			account.setPassword(BCrypt.hashpw(coachDTO.getPassword(), BCrypt.gensalt()));
			account.setRole("coach");
			account.setStatus("active");

			Useraccount savedAccCoach = repository.save(account);
			System.out.println(savedAccCoach.getUsername());
			//--教練個資
			Coach coach = new Coach();
			coach.setAccount(savedAccCoach);  //直接帶入剛剛存好的帳號資料
			coach.setName(coachDTO.getName());
			coach.setGender(coachDTO.getGender());
			coach.setPhone(coachDTO.getPhone());
			coach.setEmail(coachDTO.getEmail());
			coach.setSpecialty(coachDTO.getSpecialty());
			coach.setStatus("active");
			
			Coach savedCoach = coachRepository.save(coach);	
			//System.out.println("還沒有編號:" + savedMember);
			//先完成儲存member有自動生成的ID之後，拿ID當作尾數放入會員編號
			//也可以一開始就設定在資料庫讓他去執行編號的編碼
			String coachCode = String.format("C%06d", savedCoach.getCoachid());
			savedCoach.setCoachno(coachCode);
			
			coachRepository.save(savedCoach);
			return true;
	}
	
}
