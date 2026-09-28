package tw.gymproject.dao;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import tw.gymproject.entity.Member;

@Repository
public interface MemberRepository extends JpaRepository<Member, Integer>{

	
}
