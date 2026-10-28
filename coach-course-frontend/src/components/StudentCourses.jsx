import { fetchJson } from './detailApi'
import { useEffect, useState } from 'react'
import CourseDetailDialog from './CourseDetailDialog'

// 圖片由前端對應，課程內容由後端提供
const courseImages = {
  初階重訓: '/images/course-beginner.jpg',
  中階重訓: '/images/course-intermediate.jpg',
  高階重訓: '/images/course-advanced.jpg',
  筋膜放鬆: '/images/course-release.jpg',
  TRX: '/images/course-trx.jpg',
}

// 呼叫 API 並讀取 JSON
export default function StudentCourses() {
  const [selectedCourse, setSelectedCourse] = useState(null)
  const [selectedType, setSelectedType] = useState('全部課程')
  const [keyword, setKeyword] = useState('')
  const [sortOrder, setSortOrder] = useState('default')
  const [state, setState] = useState({
    courses: [],
    loading: true,
    error: '',
  })

  useEffect(() => {
    const controller = new AbortController()

    async function loadCourses() {
      try {
        // 先取得上架中的課程列表
        const courseList = await fetchJson(
          '/api/student/courses',
          controller.signal,
        )

        if (!Array.isArray(courseList)) {
          throw new Error('課程列表的回傳格式不是陣列。')
        }

        // 再依照各課程 ID，取得說明、時長等詳細資料
        const courseDetails = await Promise.all(
          courseList.map((course) =>
            fetchJson(
              `/api/student/courses/${course.courseid}`,
              controller.signal,
            ),
          ),
        )

        if (!controller.signal.aborted) {
          setState({
            courses: courseDetails,
            loading: false,
            error: '',
          })
        }
      } catch (error) {
        if (controller.signal.aborted) return

        setState({
          courses: [],
          loading: false,
          error: error.message,
        })
      }
    }

    loadCourses()

    // 切換頁面時，取消尚未完成的請求
    return () => controller.abort()
  }, [])

  const { courses, loading, error } = state

  // 分類選項依後端的課程類型產生
  const courseTypes = [
    '全部課程',
    ...new Set(courses.map((course) => course.coursetype).filter(Boolean)),
  ]

  // 搜尋時忽略前後空白與英文大小寫
  const searchText = keyword.trim().toLowerCase()

  // 分類與關鍵字可以同時篩選
  const visibleCourses = courses.filter((course) => {
    const matchesType =
      selectedType === '全部課程' ||
      course.coursetype === selectedType

    const searchableText = [
      course.coursename,
      course.coursetype,
      course.description,
    ]
      .filter(Boolean)
      .join(' ')
      .toLowerCase()

    return matchesType && searchableText.includes(searchText)
  })

  // filter 已產生新陣列，因此不會改動原本的 courses
  if (sortOrder === 'priceAsc') {
    visibleCourses.sort((a, b) => Number(a.price) - Number(b.price))
  } else if (sortOrder === 'priceDesc') {
    visibleCourses.sort((a, b) => Number(b.price) - Number(a.price))
  }

  return (
    <section className="cc-section">
      

      <div className="cc-course-toolbar">
        <div className="cc-course-filters" aria-label="課程分類">
          {courseTypes.map((type) => (
            <button
              key={type}
              type="button"
              className={`cc-filter-btn ${selectedType === type ? 'active' : ''
                }`}
              aria-pressed={selectedType === type}
              onClick={() => setSelectedType(type)}
            >
              {type}
            </button>
          ))}
        </div>

        <label className="cc-course-search">
          <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            aria-hidden="true"
          >
            <circle cx="10.5" cy="10.5" r="6.5" />
            <path d="m16 16 5 5" />
          </svg>

          <input
            type="search"
            value={keyword}
            onChange={(event) => setKeyword(event.target.value)}
            placeholder="輸入欲查詢的關鍵字"
            aria-label="搜尋課程"
          />
        </label>
      </div>

      {loading && (
        <p className="cc-result-count" role="status">
          課程資料讀取中……
        </p>
      )}

      {error && (
        <p className="cc-error" role="alert">
          {error}
        </p>
      )}

      {!loading && !error && (
        <>
          <div className="cc-course-results">
            <p className="cc-result-count" aria-live="polite">
              共 {visibleCourses.length} 門課程
            </p>

            <select
              className="cc-course-sort"
              value={sortOrder}
              onChange={(event) => setSortOrder(event.target.value)}
              aria-label="課程排序"
            >
              <option value="default">預設排序</option>
              <option value="priceAsc">價格由低至高</option>
              <option value="priceDesc">價格由高至低</option>
            </select>
          </div>

          {visibleCourses.length === 0 ? (
            <p className="cc-description">
              {courses.length === 0
                ? '目前沒有上架中的課程。'
                : '找不到符合條件的課程，請試試其他分類或關鍵字。'}
            </p>
          ) : (
            <div className="cc-course-grid">
              {visibleCourses.map((course) => (
                <article
                  className="cc-course-card"
                  key={course.courseid}
                >
                  <div className="cc-course-image">
                    <img
                      src={
                        courseImages[course.coursename] ||
                        '/images/banner.jpg'
                      }
                      alt={`${course.coursename}訓練示意圖`}
                      loading="lazy"
                    />

                    <span className="cc-course-type">
                      {course.coursetype}
                    </span>
                  </div>

                  <div className="cc-course-body">
                    <h3>{course.coursename}</h3>

                    <p className="cc-course-description">
                      {course.description}
                    </p>

                    <div className="cc-course-duration">
                      每堂 {course.durationmin} 分鐘
                    </div>

                    <div className="cc-course-bottom">
                      <div className="cc-course-price">
                        <span className="cc-currency">NT$</span>

                        {Number(course.price).toLocaleString('zh-TW')}

                        <span className="cc-price-unit">/單堂</span>
                      </div>

                      <button
                        type="button"
                        className="cc-detail-button"
                        aria-label={`查看${course.coursename}詳細介紹`}
                        onClick={() => setSelectedCourse(course)}
                      >
                        查看課程 ↗
                      </button>
                    </div>
                  </div>
                </article>
              ))}
            </div>
          )}
        </>
      )}

      {/* 所有課程卡片下方的標語 */}
      <div className="cc-course-slogan">
        <strong>每一次進步，都從願意開始。</strong>
        <span>專業指導 · 循序訓練 · 一起變好</span>
      </div>

      {selectedCourse && (
        <CourseDetailDialog
          key={selectedCourse.courseid}
          courseid={selectedCourse.courseid}
          imageSrc={
            courseImages[selectedCourse.coursename] || '/images/banner.jpg'
          }
          onClose={() => setSelectedCourse(null)}
        />
      )}
    </section>
  )
}