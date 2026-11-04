import assert from 'node:assert/strict'
import { test } from 'node:test'
import { appendFollowupContentShortcut, FOLLOWUP_CONTENT_SHORTCUTS } from '../src/pages/renewal/followupContentShortcutData.js'

test('常用聯繫內容附加換行、不覆蓋原文且不重複同一句', () => {
  const [shortcut] = FOLLOWUP_CONTENT_SHORTCUTS
  assert.equal(appendFollowupContentShortcut('原有內容', shortcut.text), `原有內容\n${shortcut.text}`)
  assert.equal(appendFollowupContentShortcut(`${shortcut.text}\n其他內容`, shortcut.text), `${shortcut.text}\n其他內容`)
})

test('常用內容超過既有 500 字限制時回傳失敗且不改變原文', () => {
  const original = '原文'.repeat(249)
  const result = appendFollowupContentShortcut(original, FOLLOWUP_CONTENT_SHORTCUTS[0].text)
  assert.equal(result, null)
  assert.equal(original, '原文'.repeat(249))
})

test('所有新增及編輯共用的快捷文字均有定義', () => {
  assert.deepEqual(FOLLOWUP_CONTENT_SHORTCUTS.map(({ label }) => label), ['未接聽', '稍後聯繫', '提醒上課', '說明續約', '近期較忙'])
})
