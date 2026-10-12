package com.gymproject.repository;

import com.gymproject.entity.Coach;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CoachRepository extends JpaRepository<Coach, Integer> {

    boolean existsByCoachno(String coachno);

    boolean existsByCoachnoAndCoachidNot(String coachno, Integer coachid);

    List<Coach> findByStatusOrderByCoachidAsc(String status);

    Optional<Coach> findByCoachidAndStatus(Integer coachid, String status);

}