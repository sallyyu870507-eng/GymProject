import assert from 'node:assert/strict'
import { afterEach, test } from 'node:test'
import { adminRequest, loadAdminData, saveCourseCoaches } from '../../src/features/catalog/adminApi.js'

const originalFetch = globalThis.fetch
afterEach(() => { globalThis.fetch = originalFetch })
const json = (data, status = 200) => new Response(JSON.stringify(data), { status, headers: { 'Content-Type': 'application/json' } })

test('課程設定保留教練其他課程，移除取消勾選的關聯，略過未變更者', async () => {
  const writes = []
  const current = { 1: [2, 9], 2: [2, 8], 3: [7], 4: [2, 6] }
  globalThis.fetch = async (url, init) => {
    assert.match(url, /^\/api\/coaches\/\d+\/courses$/)
    const id = Number(url.split('/')[3])
    assert.equal(init.credentials, 'include')
    if (init.method === 'GET') return json(current[id].map(courseid => ({ courseid })))
    writes.push([id, JSON.parse(init.body).courseids])
    return json({})
  }
  await saveCourseCoaches(2, [1, 3], [1, 2, 3, 4].map(coachid => ({ coachid })))
  assert.deepEqual(writes, [[2, [8]], [3, [7, 2]], [4, [6]]])
})

test('部分關聯儲存失敗時停止並回報端點、狀態與後端訊息', async () => {
  const urls = []
  globalThis.fetch = async (url, init) => {
    urls.push(url)
    return init.method === 'GET' ? json([]) : json({ message: '沒有操作權限' }, 403)
  }
  await assert.rejects(saveCourseCoaches(2, [1, 2], [{ coachid: 1 }, { coachid: 2 }]), /PUT \/api\/coaches\/1\/courses（403）：沒有操作權限/)
  assert.equal(urls.length, 2)
})

test('列表關聯依 API 實際資料，不由專長字串推算', async () => {
  globalThis.fetch = async url => {
    if (url === '/api/coaches') return json([{ coachid: 11, specialty: '錯誤專長文字' }])
    if (url === '/api/courses') return json([{ courseid: 25, coursename: '新課程' }])
    assert.equal(url, '/api/coaches/11/courses')
    return json([{ courseid: 25 }])
  }
  const data = await loadAdminData()
  assert.deepEqual(data.relations, { 11: [25] })
})

test('關聯回傳格式錯誤不可當作空白清單而覆寫', async () => {
  globalThis.fetch = async () => json({ message: '非陣列' })
  await assert.rejects(saveCourseCoaches(2, [], [{ coachid: 1 }]), /資料格式不正確/)
})

test('登入頁 HTML 與未授權回應均不可判定為儲存成功', async () => {
  globalThis.fetch = async () => new Response('<html>登入</html>', { headers: { 'Content-Type': 'text/html' } })
  await assert.rejects(adminRequest('/api/admin/courses', 'POST', {}), /未收到 JSON/)
  globalThis.fetch = async () => json({}, 401)
  await assert.rejects(adminRequest('/api/user'), /401.*請先登入/)
})
