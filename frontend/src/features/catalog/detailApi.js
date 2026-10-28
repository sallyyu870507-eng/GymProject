import { sessionFetch } from '../../sessionFetch.js'
export const courseImages = {
  初階重訓: '/images/course-beginner.jpg',
  中階重訓: '/images/course-intermediate.jpg',
  高階重訓: '/images/course-advanced.jpg',
  筋膜放鬆: '/images/course-release.jpg',
  TRX: '/images/course-trx.jpg',
}

const coachImages = {
  AMY: '/images/coach-amy.jpg',
  BEN: '/images/coach-ben.jpg',
  CHRIS: '/images/coach-chris.jpg',
  DAVID: '/images/coach-david.jpg',
  ERIC: '/images/coach-eric.jpg',
}

export function coachImage(name) {
  return coachImages[name?.trim().toUpperCase()]
}

export async function fetchJson(url, signal) {
  const response = await sessionFetch(url, {
    signal,
    credentials: 'same-origin',
    headers: { Accept: 'application/json' },
  })
  if (!response.ok) {
    const error = new Error(
      `讀取 ${url} 失敗（HTTP ${response.status}）：${
        response.status === 401 ? '尚未登入或登入已失效；測試模式不會授予後端登入權限。'
          : response.status === 403 ? '後端拒絕存取，目前身分沒有此 API 的權限。'
            : response.status === 404 ? '資料已下架、停用或不存在。'
              : '請確認後端服務狀態。'
      }`,
    )
    error.status = response.status
    throw error
  }
  if (!(response.headers.get('content-type') || '').includes('application/json')) {
    throw new Error('未取得 JSON 資料，請確認登入狀態與代理設定。')
  }
  return response.json()
}

function requireArray(value) {
  if (!Array.isArray(value)) throw new Error('列表資料格式不正確。')
  return value
}

// 使用既有管理端關聯 API；以學員端列表過濾停用教練與下架課程。
export async function loadRelated(kind, id, signal) {
  if (kind === 'coach') {
    const [assigned, active] = await Promise.all([
      fetchJson(`/api/coaches/${id}/courses`, signal),
      fetchJson('/api/student/courses', signal),
    ])
    const ids = new Set(requireArray(assigned).map((c) => String(c.courseid)))
    return requireArray(active).filter((c) => ids.has(String(c.courseid)))
  }

  const coaches = requireArray(await fetchJson('/api/student/coaches', signal))
  const matches = await Promise.all(coaches.map(async (coach) => {
    const assigned = requireArray(
      await fetchJson(`/api/coaches/${coach.coachid}/courses`, signal),
    )
    return assigned.some((c) => String(c.courseid) === String(id)) ? coach : null
  }))
  return matches.filter(Boolean)
}
