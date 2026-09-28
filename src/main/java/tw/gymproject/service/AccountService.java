package tw.gymproject.service;

import org.hibernate.service.spi.Stoppable;
import org.mindrot.jbcrypt.BCrypt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import jakarta.transaction.Transactional;
import tw.gymproject.dao.AccountRepository;
import tw.gymproject.dao.MemberRepository;
import tw.gymproject.dto.RegisterDTO;
import tw.gymproject.entity.Member;
import tw.gymproject.entity.Useraccount;

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

	AccountService(AccountRepository repository,MemberRepository memberRepository) {
		this.repository = repository;
		this.memberRepository = memberRepository;
	}	
	
//	public boolean checkAccount(String account) {
//		return repository.existsByUsername(account);
//		}
	
	//建立帳號
	public boolean registerMember(RegisterDTO dto) { //使用物件類別，可以一次拿到多個參數，即使是null也只會顯示null
		//檢查帳號是否重複
		if(!repository.existsByUsername(dto.getUsername())) {
		
		 //註冊、建立帳號
		Useraccount account = new Useraccount();
		account.setUsername(dto.getUsername());
		account.setPassword(BCrypt.hashpw(dto.getPassword(), BCrypt.gensalt()));
		account.setRole("member");
		account.setSatus("active");
		
		//裝到變數內較清楚，後面與member表資料連接用
		Useraccount savedUseraccount = repository.save(account);
		System.out.println(savedUseraccount);
		
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
		System.out.println("還沒有編號:" + savedMember);
		//先完成儲存member有自動生成的ID之後，拿ID當作尾數放入會員編號
		//也可以一開始就設定在資料庫讓他去執行編號的編碼
		String membercode = String.format("M%06d", savedMember.getMemberid());
		savedMember.setMemberno(membercode);
		
		memberRepository.save(savedMember);
		System.out.println("生成編號加入資料表:" +savedMember);

		return true; //註冊成功
	}else	
		return false;	//利用這個false在前端顯示已註冊
	}
	
	
	
	
	
	
	

}









