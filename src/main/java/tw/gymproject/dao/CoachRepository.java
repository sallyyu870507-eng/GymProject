package tw.gymproject.dao;

import org.springframework.data.jpa.repository.JpaRepository;
import tw.gymproject.entity.Coach;

import java.util.List;
import java.util.Optional;

public interface CoachRepository extends JpaRepository<Coach, Integer> {

	Optional<Coach> findByAccount_Accountid(Integer accountid);

	boolean existsByCoachno(String coachno);

	boolean existsByCoachnoAndCoachidNot(String coachno, Integer coachid);

	List<Coach> findByStatusOrderByCoachidAsc(String status);

	Optional<Coach> findByCoachidAndStatus(Integer coachid, String status);
}