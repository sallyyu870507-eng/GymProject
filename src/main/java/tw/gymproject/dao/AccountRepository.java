package tw.gymproject.dao;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import tw.gymproject.entity.Useraccount;
import java.util.List;
import java.util.Optional;


//會自動帶入多項spring功能
@Repository
public interface AccountRepository 
extends JpaRepository<Useraccount, Integer>{
	
	//檢查帳號是否已經存在
	boolean existsByUsername(String username); //spring功能
	
	//方法名稱也要對到username，因為內建會去解析命名規則來建立SQL查詢指令
	//查最新的，避免有被軟刪除又再重瓣的會員會取出不只一位而報錯
	Optional<Useraccount> findFirstByUsernameOrderByAccountidDesc(String username); //Optional只能是0個或1個

}
