import assert from 'node:assert/strict'
import { test } from 'node:test'
import { createNavigationGuard } from '../src/navigationGuard.js'

const location = (pathname, search = '', hash = '') => ({ pathname, search, hash })

test('重現成功導覽在提交鎖解除前會被舊條件誤擋，修正後只放行指定目標', () => {
  const guard = createNavigationGuard()
  const currentLocation = location('/renewal/4/followups/new')
  const nextLocation = location('/renewal/4', '?tab=followups')
  const oldBlockerDecision = (hasUnsavedChanges, navigationLocked) =>
    (hasUnsavedChanges || navigationLocked)
      && currentLocation.pathname !== nextLocation.pathname

  // POST 已成功、dirty 已清除，但 finally 尚未解除 navigationLocked。
  assert.equal(oldBlockerDecision(false, true), true)
  guard.allowNextNavigationTo('/renewal/4?tab=followups')

  assert.equal(guard.shouldBlock({
    currentLocation,
    nextLocation,
    hasUnsavedChanges: false,
    navigationLocked: true,
  }), false)

  assert.equal(guard.shouldBlock({
    currentLocation: location('/renewal/4'),
    nextLocation: location('/renewal'),
    hasUnsavedChanges: true,
    navigationLocked: false,
  }), true)
})

test('成功導覽許可不匹配時不會放行，且不會殘留到後續手動導覽', () => {
  const guard = createNavigationGuard()
  guard.allowNextNavigationTo('/renewal/4?tab=followups')

  const context = {
    currentLocation: location('/renewal/4/followups/new'),
    nextLocation: location('/renewal/5', '?tab=followups'),
    hasUnsavedChanges: true,
    navigationLocked: false,
  }
  assert.equal(guard.shouldBlock(context), true)
  assert.equal(guard.shouldBlock(context), true)
})

test('使用者主動離開髒表單仍會被阻擋', () => {
  const guard = createNavigationGuard()
  assert.equal(guard.shouldBlock({
    currentLocation: location('/renewal/4/followups/new'),
    nextLocation: location('/renewal'),
    hasUnsavedChanges: true,
    navigationLocked: false,
  }), true)
})
