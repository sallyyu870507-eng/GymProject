import assert from 'node:assert/strict'
import { test } from 'node:test'
import { createNotificationStore } from '../src/notifications.js'

test('確認前不執行操作；取消與重複回答都不會送出操作', async () => {
  const store = createNotificationStore()
  let writes = 0
  const operation = async () => { if (await store.confirm('停用會員？')) writes++ }
  const cancelled = operation()
  assert.equal(writes, 0)
  const id = store.getSnapshot().confirmation.id
  store.answer(id, false)
  store.answer(id, true)
  await cancelled
  assert.equal(writes, 0)
  assert.equal(store.getSnapshot().confirmation, null)

  const accepted = operation()
  assert.equal(writes, 0)
  const nextId = store.getSnapshot().confirmation.id
  store.answer(nextId, true)
  store.answer(nextId, true)
  await accepted
  assert.equal(writes, 1)
})

test('多個確認依序顯示，各自取得正確的確認結果', async () => {
  const store = createNotificationStore()
  const first = store.confirm('第一個')
  const firstId = store.getSnapshot().confirmation.id
  const second = store.confirm('第二個')
  assert.equal(store.getSnapshot().confirmation.message, '第一個')
  store.answer(firstId, true)
  assert.equal(await first, true)
  assert.equal(store.getSnapshot().confirmation.message, '第二個')
  store.answer(store.getSnapshot().confirmation.id, false)
  assert.equal(await second, false)
})

test('路由確認失效時取消該請求，保留其他待處理確認', async () => {
  const store = createNotificationStore()
  const controller = new AbortController()
  const navigation = store.confirm('離開？', { signal: controller.signal })
  const other = store.confirm('其他操作')
  controller.abort()
  assert.equal(await navigation, false)
  assert.equal(store.getSnapshot().confirmation.message, '其他操作')
  store.cancelAll()
  assert.equal(await other, false)
  assert.equal(store.getSnapshot().confirmation, null)
  assert.equal(await store.confirm('已取消', { signal: controller.signal }), false)
})

test('關閉 Toast 只移除指定訊息，不影響確認視窗或其他通知', async () => {
  const store = createNotificationStore()
  const accepted = store.confirm('確認？')
  const first = store.toast('已儲存', { type: 'success' })
  const second = store.toast('讀取失敗', { type: 'error' })
  store.removeToast(first)
  assert.deepEqual(store.getSnapshot().toasts.map(toast => toast.id), [second])
  assert.equal(store.getSnapshot().toasts[0].type, 'error')
  assert.equal(store.getSnapshot().confirmation.message, '確認？')
  store.cancelAll()
  assert.equal(await accepted, false)
})
