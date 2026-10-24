package tw.gymproject.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import tw.gymproject.entity.Membercourse;

public interface AdminMemberCourseRepo extends JpaRepository<Membercourse, Integer> {

}
