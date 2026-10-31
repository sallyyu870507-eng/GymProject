import { fetchJson } from './detailApi'
import { useEffect, useState } from 'react'
import CoachDetailDialog from './CoachDetailDialog'

const coachImages = {
    AMY: '/images/coach-amy.jpg',
    BEN: '/images/coach-ben.jpg',
    CHRIS: '/images/coach-chris.jpg',
    DAVID: '/images/coach-david.jpg',
    ERIC: '/images/coach-eric.jpg',
}

export default function StudentCoaches() {
    const [selectedCoach, setSelectedCoach] = useState(null)
    const [keyword, setKeyword] = useState('')

    const [state, setState] = useState({
        coaches: [],
        loading: true,
        error: '',
    })

    useEffect(() => {
        const controller = new AbortController()

        async function loadCoaches() {
            try {
                const coachList = await fetchJson(
                    '/api/member/student/coaches',
                    controller.signal,
                )

                if (!Array.isArray(coachList)) {
                    throw new Error('教練列表的回傳格式不是陣列。')
                }

                // 列表只有編號與姓名，另外取得詳細資料中的專長
                const coachDetails = await Promise.all(
                    coachList.map((coach) =>
                        fetchJson(
                            `/api/member/student/coaches/${coach.coachid}`,
                            controller.signal,
                        ),
                    ),
                )

                if (!controller.signal.aborted) {
                    setState({
                        coaches: coachDetails,
                        loading: false,
                        error: '',
                    })
                }
            } catch (error) {
                if (controller.signal.aborted) return

                setState({
                    coaches: [],
                    loading: false,
                    error: error.message,
                })
            }
        }

        loadCoaches()

        return () => controller.abort()
    }, [])

    const { coaches, loading, error } = state
    const searchText = keyword.trim().toLowerCase()

    const visibleCoaches = coaches.filter((coach) => {
        const searchableText = [coach.name, coach.specialty]
            .filter(Boolean)
            .join(' ')
            .toLowerCase()

        return searchableText.includes(searchText)
    })

    return (
        <section className="cc-section">


            <div className="cc-coach-toolbar">
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
                        aria-label="搜尋教練姓名或專長"
                    />
                </label>
            </div>

            {loading && (
                <p className="cc-result-count" role="status">
                    教練資料讀取中……
                </p>
            )}

            {error && (
                <p className="cc-error" role="alert">
                    {error}
                </p>
            )}

            {!loading && !error && (
                <>
                    <p className="cc-result-count" aria-live="polite">
                        共 {visibleCoaches.length} 位教練
                    </p>

                    {visibleCoaches.length === 0 ? (
                        <p className="cc-description">
                            {coaches.length === 0
                                ? '目前沒有可顯示的教練。'
                                : '找不到符合條件的教練，請試試其他關鍵字。'}
                        </p>
                    ) : (
                        <div className="cc-coach-grid">
                            {visibleCoaches.map((coach) => {
                                const imageSrc =
                                    coachImages[coach.name?.trim().toUpperCase()]

                                return (
                                    <article
                                        className="cc-coach-card"
                                        key={coach.coachid}
                                    >
                                        <div className="cc-coach-image">
                                            {imageSrc ? (
                                                <img
                                                    src={imageSrc}
                                                    alt={`${coach.name}教練`}
                                                    loading="lazy"
                                                />
                                            ) : (
                                                <span className="cc-coach-placeholder">
                                                    教練照片準備中
                                                </span>
                                            )}
                                        </div>

                                        <div className="cc-coach-body">
                                            <span className="cc-coach-label">
                                                專業教練
                                            </span>

                                            <h3>{coach.name}</h3>



                                            <div className="cc-coach-specialties">
                                                {coach.specialty?.trim() ? (
                                                    coach.specialty
                                                        .split(/[、，,·・;\n；]+/)
                                                        .map((item) => item.trim())
                                                        .filter(Boolean)
                                                        .map((specialty, index) => (
                                                            <span
                                                                className="cc-coach-specialty-tag"
                                                                key={`${specialty}-${index}`}
                                                            >
                                                                {specialty}
                                                            </span>
                                                        ))
                                                ) : (
                                                    <span className="cc-description">
                                                        專長資料準備中。
                                                    </span>
                                                )}
                                            </div>
                                            <div className="cc-coach-card-footer">
                                                <button
                                                    type="button"
                                                    className="cc-detail-button"
                                                    aria-label={`認識${coach.name}教練`}
                                                    onClick={() => setSelectedCoach(coach)}
                                                >
                                                    認識教練 ↗
                                                </button>
                                            </div>
                                        </div>
                                    </article>
                                )
                            })}
                        </div>
                    )}
                </>
            )}
            {/* 所有教練卡片下方的標語 */}
            <div className="cc-course-slogan">
                <strong>每一次進步，都從願意開始。</strong>
                <span>專業指導 · 循序訓練 · 一起變好</span>
            </div>
            {selectedCoach && (
                <CoachDetailDialog
                    key={selectedCoach.coachid}
                    coachid={selectedCoach.coachid}
                    imageSrc={
                        coachImages[selectedCoach.name?.trim().toUpperCase()]
                    }
                    onClose={() => setSelectedCoach(null)}
                />
            )}
        </section>
    )
}