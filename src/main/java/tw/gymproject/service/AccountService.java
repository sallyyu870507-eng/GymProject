package tw.gymproject.service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.mindrot.jbcrypt.BCrypt;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import jakarta.persistence.EntityNotFoundException;
//import tw.gymproject.dto.LoginDTO;
import tw.gymproject.dto.LoginResultDTO;
import tw.gymproject.dto.MemberCourseDTO;
import tw.gymproject.dto.MemberListDTO;
import tw.gymproject.dto.MemberUpdateDTO;
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
//會員的功能邏輯
public class AccountService {
//	欄位注入
//	@Autowired
//	private AccountRepository repository;
	
	//把會用到的repository，建構式注入
	private final AccountRepository repository;
	private final MemberRepository memberRepository;
	private final CoachRepository coachRepository;
	
	AccountService(AccountRepository repository,MemberRepository memberRepository, CoachRepository coachRepository) {
		this.repository = repository;
		this.memberRepository = memberRepository;
		this.coachRepository = coachRepository;
	}	
	
	//建立會員帳號
	public boolean registerMember(RegisterDTO dto) { //使用物件類別，可以一次拿到多個參數，即使是null也只會顯示null
		//檢查帳號是否重複
		if(repository.existsByUsername(dto.getUsername())) {
			throw new DuplicateUsernameException(
					"帳號已存在，請更換其他名稱");}//也有可能停用，洽館員
		
		 //註冊、建立帳號
		Useraccount account = new Useraccount();
		account.setUsername(dto.getUsername().trim());
		account.setPassword(BCrypt.hashpw(dto.getPassword(), BCrypt.gensalt()));
		account.setRole("member");
		account.setStatus("active");
		
		//裝到變數內較清楚，後面與member表資料連接用
		Useraccount savedUseraccount = repository.save(account);
		
		//建立會員資料
		Member member = new Member();
		member.setAccount(savedUseraccount);  //直接帶入剛剛存好的帳號資料
		member.setName(dto.getName());
		member.setGender(dto.getGender());
		member.setPhone(dto.getPhone());
		member.setEmail(dto.getEmail());
		member.setBirthday(dto.getBirthday());
		member.setStatus("active");
		
		Member savedMember = memberRepository.save(member);
		//System.out.println("還沒有編號:" + savedMember);
		//先完成儲存member有自動生成的ID之後，拿ID當作尾數放入會員編號
		//也可以一開始就設定在資料庫讓他去執行編號的編碼
		String membercode = String.format("M%06d", savedMember.getMemberid());
		savedMember.setMemberno(membercode);
		
		memberRepository.save(savedMember);

		return true; //註冊成功
	}
	//-----------------------------------------------------
	//首頁登入
	public LoginResultDTO login(String username, String password) {
		//找出最新的一筆帳號資料
		Optional<Useraccount> userOpt = repository.findFirstByUsernameOrderByAccountidDesc(username); //用Optional偵測是否為空用isEmpty
		
		LoginResultDTO result = new LoginResultDTO();
		//無此帳號
		if (userOpt.isEmpty()) {
			result.setSuccess(false);
			result.setStatus("INVALID");
			return result;
		}
		
		//如果有帳號才往下
		Useraccount account = userOpt.get();
		System.out.println(account.getUsername());
		//帳號停用
		if("inactive".equals(account.getStatus())) {
			result.setSuccess(false);
			result.setStatus("INACTIVE");
			return result;
		}		
		if (!BCrypt.checkpw(password, account.getPassword())) {
			result.setSuccess(false);
			result.setStatus("INVALID");
			return result;
		}		
		
		result.setAccountid(account.getAccountid());
		result.setUsername(account.getUsername());
		result.setRole(account.getRole());
		if("member".equals(account.getRole())) {
			Optional<Member> memberOpt = memberRepository.findByAccount_Accountid(account.getAccountid()); //為了拿到會員姓名寫歡迎
			
			if (memberOpt.isEmpty()) {
				result.setSuccess(false);
		        result.setStatus("MEMBER_NOT_FOUND");
		        return result;
			}
			Member member = memberOpt.get();
			result.setName(member.getName());
			result.setMemberno(member.getMemberno());
			result.setMemberid(member.getMemberid());
			
		}else if("coach".equals(account.getRole())) {
			Optional<Coach> coachOpt = coachRepository.findByAccount_Accountid(account.getAccountid()); //同理為了取得教練姓名
			if (coachOpt.isEmpty()) {
				result.setSuccess(false);
		        result.setStatus("COACH_NOT_FOUND");
		        return result;
			}
			Coach coach = coachOpt.get();
			result.setName(coach.getName());
			result.setCoachno(coach.getCoachno());
			result.setCoachid(coach.getCoachid());			
			
		}else if ("admin".equals(account.getRole())) {

	        result.setName("管理員");
	        
	    }else {
	    		//若都沒有就填入false再回傳
		result.setSuccess(false);
		result.setStatus("INVALID_ROLE");

		return result;
	    }
		
			result.setSuccess(true);
			result.setStatus("SUCCESS");
	        return result;
	}
	//-------------------------------------------------

	//會員清單分頁
	//使用雙層DTO，先用entity抓會員基本資料，再用SQL語法查資料庫的課程堂數
	public Map<String, Object> findAllMembers(int page, 
												int size, 
												String status, 
												String keyword) {  //回傳給Controller
		//設定當前分頁該顯示的會員的分頁條件
		Pageable pageable = PageRequest.of(page, size, Sort.by("memberid").ascending());//建立分頁條件
		//把分頁條件交給repository去執行撈entity的工作
		Page<Member> memberPage =
		        memberRepository.searchMembers(keyword,
								                status,
								                pageable
				);
		
		//篩選狀態+關鍵字搜尋
		if (!List.of("all", "active", "inactive").contains(status)) {
		    throw new IllegalArgumentException("無效的會員狀態");
		}
		
		//建立Map放會員資料，撈出會員資料要放到容器Map裡，用迴圈放
		Map<Integer, MemberListDTO> memberMap = new LinkedHashMap<>();  //有順序的放入，先進先出
		
		for (Member member : memberPage.getContent()) { //memberPage.getContent()可以得到從entity取出的資料內容
			
			MemberListDTO dto = new MemberListDTO();
			dto.setAccountid(member.getAccount().getAccountid());
			dto.setMemberid(member.getMemberid());
			dto.setMemberno(member.getMemberno());
			dto.setName(member.getName());
			dto.setGender(member.getGender());
			dto.setPhone(member.getPhone());
			dto.setStatus(member.getStatus());
			dto.setCourses(new ArrayList<>()); //後面再接著抓每一個會員的會員課程內容
			
			//把會員放進Map，是Key-value的形式，id當Key，資料是value
			memberMap.put(member.getMemberid(), dto);
		
		}
		
		//再來因為repositroy寫的SQL語法是靠memberid撈課程資料
		//所以必須取出出每個會員的memberid給repository用
		//用KeySet()取出id型別是Set<Integer>是一種collection可以放入ArrayList建構式
		List<Integer> memberids = new ArrayList<>(memberMap.keySet()); //就可以給repository用
		List<Object[]> rowList = memberids.isEmpty()?   //如果當頁沒有會員
				List.of():				//就回傳一個固定不可更動的空List，就不用對資料庫進行空值查詢避免錯誤
				memberRepository.findMemberCourses(memberids);  //當頁有會員才執行查詢

		
		for(Object[] rowObjects : rowList) {
			//先把物件轉型成Number，是各種數值類別的父類，不怕傳回來的是哪種都可以套inValue變成這裡的Integer
			Integer memberId = ((Number) rowObjects[0]).intValue(); 
			
			MemberListDTO memberListDTO = memberMap.get(memberId); //取得指定id會員元素
			MemberCourseDTO memberCourseDTO = new MemberCourseDTO();
			
			memberCourseDTO.setCourseid(((Number) rowObjects[1]).intValue());
			memberCourseDTO.setCoursename((String)rowObjects[2]);
			memberCourseDTO.setCoachid(((Number)rowObjects[3]).intValue());
			memberCourseDTO.setName((String) rowObjects[4]);
			memberCourseDTO.setRemainingsessions(((Number)rowObjects[5]).intValue());
			
			memberListDTO.getCourses().add(memberCourseDTO); 
			//用加的，如果直接set，每跑一次迴圈上一圈的內容就會被新的覆蓋掉			
		}
		//因為要寫分頁功能，除了memberListDTO的內容之外，還需要page的各種分頁資訊，所以重組成Map回傳
		Map<String, Object> result = new HashMap<>();

		result.put("members", new ArrayList<>(memberMap.values()));  //前面拚出來的MemberList，
		result.put("currentPage", memberPage.getNumber()); //目前頁碼
		result.put("pageSize", memberPage.getSize()); //每頁幾筆
		result.put("totalPages", memberPage.getTotalPages()); //總頁數
		result.put("totalElements", memberPage.getTotalElements()); //總會員數
		result.put("hasNext", memberPage.hasNext()); //boolean是否有下一頁
		result.put("hasPrev", memberPage.hasPrevious()); //boolean是否有上一頁
		
		return result; //交給controller整理給前端
		
}
	
	
	
	
	//編輯會員資料，先查 後改
	public MemberUpdateDTO getMemberForEdit(Integer memberid) {

        Member member = memberRepository.findById(memberid)
            .orElseThrow(() ->
                new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "找不到會員"
                )
            );

        MemberUpdateDTO dto = new MemberUpdateDTO();
        
        dto.setUsername(member.getAccount().getUsername());
        dto.setName(member.getName());
        dto.setPhone(member.getPhone());
        dto.setEmail(member.getEmail());

        return dto;
    }

	//編輯會員資料，更新
    public void updateMember(
            Integer memberid,
            MemberUpdateDTO dto) {

        // 取得原本的會員
        Member member = memberRepository.findById(memberid)
            .orElseThrow(() ->
                new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "找不到會員"
                )
            );
        Useraccount account = member.getAccount();
        // 檢查比對傳進來的username有無改變
        if (!account.getUsername().equals(dto.getUsername())) {

            // 檢查新帳號有沒有被使用
            if (repository.existsByUsername(dto.getUsername())) {
                throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "帳號已被使用"
                );
            }

            account.setUsername(dto.getUsername());
        }

        member.setName(dto.getName());
        member.setPhone(dto.getPhone());
        member.setEmail(dto.getEmail());

        // 由 JPA 自動更新資料庫，這邊不是新增，不用save
    }

	
	//刪除帳號
	//因為Entity已經有跟member和coach聯集了
	public void softDeleteAccount(Integer accountid) {
        // 查出主表資料
        Useraccount account = repository.findById(accountid)
            .orElseThrow(() -> new EntityNotFoundException("找不到該帳號")); //如果找不到帳號，丟出去給全域處理器
        
        Member member = memberRepository
    	        .findByAccount_Accountid(accountid)
    	        .orElseThrow(() ->
    	            new EntityNotFoundException("找不到會員"));

    	    if ("inactive".equals(account.getStatus())
    	            && "inactive".equals(member.getStatus())) {
    	        throw new IllegalStateException("會員已是停用狀態");
    	    }
    	    
    	    //使用set更改狀態不用saved
    	    account.setStatus("inactive");//這邊走的是一般的更改欄位方式
    	    member.setStatus("inactive");
        
       
    }
	
	//恢復帳號
	@Transactional
	public void reactivateMember(Integer accountid) {

	    Useraccount account = repository
	        .findById(accountid)
	        .orElseThrow(() ->
	            new EntityNotFoundException("找不到帳號"));

	    Member member = memberRepository
	        .findByAccount_Accountid(accountid)
	        .orElseThrow(() ->
	            new EntityNotFoundException("找不到會員"));

	    if ("active".equals(account.getStatus())
	            && "active".equals(member.getStatus())) {
	        throw new IllegalStateException("會員已是啟用狀態");
	    }

	    account.setStatus("active");
	    member.setStatus("active");
	}

	//檢查密碼是否符合當初輸入的
//	public boolean verifyPassword(String username, String rawPassword) {
//	    Useraccount account = repository
//	        .findFirstByUsernameOrderByAccountidDesc(username)
//	        .orElseThrow(() -> new IllegalArgumentException("找不到帳號"));
//
//	    return BCrypt.checkpw(rawPassword, account.getPassword());
//	}
}









