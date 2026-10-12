package com.gymproject.repository;

import com.gymproject.entity.CoachCourse;
import com.gymproject.entity.CoachCourseId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CoachCourseRepository extends JpaRepository<CoachCourse, CoachCourseId> {

    List<CoachCourse> findById_Coachid(Integer coachid);

}