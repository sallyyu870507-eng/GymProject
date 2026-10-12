package com.gymproject.service;

import com.gymproject.dto.CoachCoursesRequest;
import com.gymproject.entity.CoachCourse;
import com.gymproject.repository.CoachCourseRepository;
import com.gymproject.repository.CoachRepository;
import com.gymproject.repository.CourseRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import com.gymproject.entity.Course;

@Service
public class CoachCourseService {

    private final CoachCourseRepository coachCourseRepository;
    private final CoachRepository coachRepository;
    private final CourseRepository courseRepository;

    public CoachCourseService(
            CoachCourseRepository coachCourseRepository,
            CoachRepository coachRepository,
            CourseRepository courseRepository) {

        this.coachCourseRepository = coachCourseRepository;
        this.coachRepository = coachRepository;
        this.courseRepository = courseRepository;
    }

    @Transactional
    public List<Integer> setCourses(
            Integer coachid,
            CoachCoursesRequest request) {

        // 1. 確認教練存在
        if (!coachRepository.existsById(coachid)) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "找不到此教練");
        }

        // 2. 移除重複的課程 ID
        Set<Integer> requestedIds =
                new LinkedHashSet<>(request.getCourseids());

        // 3. 先確認所有課程存在，才開始修改
        for (Integer courseid : requestedIds) {
            if (!courseRepository.existsById(courseid)) {
                throw new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "找不到課程 ID：" + courseid);
            }
        }

        // 4. 查詢教練目前的配對
        List<CoachCourse> existing =
                coachCourseRepository.findById_Coachid(coachid);

        Set<Integer> existingIds = existing.stream()
                .map(item -> item.getId().getCourseid())
                .collect(Collectors.toSet());

        // 5. 刪除這次沒有選擇的配對
        List<CoachCourse> toDelete = existing.stream()
                .filter(item -> !requestedIds.contains(
                        item.getId().getCourseid()))
                .toList();

        coachCourseRepository.deleteAll(toDelete);

        // 6. 新增原本沒有的配對
        List<CoachCourse> toAdd = requestedIds.stream()
                .filter(courseid -> !existingIds.contains(courseid))
                .map(courseid -> new CoachCourse(coachid, courseid))
                .toList();

        coachCourseRepository.saveAll(toAdd);

        return new ArrayList<>(requestedIds);
    }

    @Transactional(readOnly = true)
    public List<Course> getCoursesByCoach(Integer coachid) {

        // 確認教練存在
        if (!coachRepository.existsById(coachid)) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "找不到此教練");
        }

        // 從關聯表取得這位教練的課程 ID
        List<Integer> courseids =
                coachCourseRepository.findById_Coachid(coachid)
                        .stream()
                        .map(item -> item.getId().getCourseid())
                        .toList();

        // 查詢完整課程資料，再依課程 ID 排序
        List<Course> courses =
                courseRepository.findAllById(courseids);

        courses.sort(
                java.util.Comparator.comparing(Course::getCourseid)
        );

        return courses;
    }
}