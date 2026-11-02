import { useEffect, useState } from 'react';
import { Link } from 'react-router';
import { request } from '../../../../api.js';
import { Card } from '../../components/ui';

//每筆以 membercourseid 區分，避免同一門課購買多個方案時被合併或漏掉。
type PurchasedCourse = {
  membercourseid: number;
  courseid: number;
  coursename: string;
  coachid: number;
  coachname: string;
  remainingsessions: number;
};

export default function PurchasedCoursesCard() {
  const [courses, setCourses] = useState<PurchasedCourse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    const controller = new AbortController();

    setLoading(true);
    setError('');

    request('/api/member/courses', {
      signal: controller.signal,
    })
      .then((data) => {
        if (controller.signal.aborted) return;
        if (!Array.isArray(data)) {
          throw new Error('已購課程回傳格式不正確');
        }
        setCourses(data);
      })
      .catch((failure: unknown) => {
        if (controller.signal.aborted) return;
        setCourses([]);
        setError(
          failure instanceof Error
            ? failure.message
            : '已購課程讀取失敗',
        );
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });

    return () => controller.abort();
  }, [attempt]);

  return (
    <Card
      title="已購課程"
      subtitle="啟用中且仍有剩餘堂數的方案"
      footer={
        <>
          <button
            type="button"
            className="btn"
            disabled={loading}
            onClick={() => setAttempt((value) => value + 1)}
          >
            重新讀取
          </button>

          <Link to="/book-course" className="btn">
            前往預約
          </Link>
        </>
      }
    >
      {loading ? (
        <p role="status">已購課程載入中…</p>
      ) : error ? (
        <p role="alert">{error}</p>
      ) : !courses.length ? (
        <p className="muted">目前沒有可預約的剩餘課程。</p>
      ) : (
        <div className="course-list">
          {courses.map((course) => (
            <Link
              key={course.membercourseid}
              to={`/book-course?membercourseid=${course.membercourseid}`}
              className="course-card"
              style={{ color: 'inherit', textDecoration: 'none' }}
              aria-label={`預約 ${course.coursename}，${course.coachname}教練，方案 ${course.membercourseid}，剩餘 ${course.remainingsessions} 堂`}
            >
              <div className="course-top">
                <strong className="course-name">
                  {course.coursename || '未提供課程名稱'}
                </strong>
                <span>
                  剩餘 {course.remainingsessions} 堂
                </span>
              </div>

              <p className="muted">
                教練：{course.coachname || '未提供'}
              </p>
            </Link>
          ))}
        </div>
      )}
    </Card>
  );
}
