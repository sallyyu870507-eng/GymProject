export async function adminRequest(url, method = 'GET', body, signal) {
  const response = await fetch(url, {
    method, credentials: 'include', signal,
    headers: { Accept: 'application/json', ...(body === undefined ? {} : { 'Content-Type': 'application/json' }) },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  })
  const text = await response.text()
  let data
  try { data = text ? JSON.parse(text) : null } catch { data = null }
  if (!response.ok) {
    const fallback = { 401: '請先登入管理員帳號。', 403: '沒有操作權限。', 404: '找不到資料。', 409: '資料發生衝突。' }
    const detail = data?.detail || data?.message || data?.error || (data && Object.keys(data).length ? JSON.stringify(data) : '') || (!data && text && !text.trim().startsWith('<') ? text : '') || fallback[response.status] || '請求失敗'
    throw new Error(`${method} ${url}（${response.status}）：${typeof detail === 'string' ? detail : JSON.stringify(detail)}`)
  }
  if (response.redirected || (text && !response.headers.get('content-type')?.includes('application/json'))) {
    throw new Error(`${method} ${url}：未收到 JSON，請確認登入狀態。`)
  }
  return data
}

export async function assignedCourses(coachid, signal) {
  const list = await adminRequest(`/api/coaches/${coachid}/courses`, 'GET', undefined, signal)
  if (!Array.isArray(list)) throw new Error(`教練 ${coachid} 的課程資料格式不正確`)
  return list
}

export async function loadAdminData(signal) {
  const [coaches, courses] = await Promise.all([
    adminRequest('/api/coaches', 'GET', undefined, signal),
    adminRequest('/api/courses', 'GET', undefined, signal),
  ])
  if (!Array.isArray(coaches) || !Array.isArray(courses)) throw new Error('教練或課程列表的回傳格式不是陣列')
  const lists = await Promise.all(coaches.map(async coach => ({
    coachid: coach.coachid,
    courseids: (await assignedCourses(coach.coachid, signal)).map(course => course.courseid),
  })))
  return { coaches, courses, relations: Object.fromEntries(lists.map(item => [item.coachid, item.courseids])) }
}

// 每次更新前重讀完整關聯，只增刪目前這門課程。
export async function saveCourseCoaches(courseid, selectedIds, coaches) {
  for (const coach of coaches) {
    const current = await assignedCourses(coach.coachid)
    const ids = new Set(current.map(course => course.courseid))
    const selected = selectedIds.includes(coach.coachid)
    if (ids.has(courseid) === selected) continue
    if (selected) ids.add(courseid)
    else ids.delete(courseid)
    await adminRequest(`/api/coaches/${coach.coachid}/courses`, 'PUT', { courseids: [...ids] })
  }
}
