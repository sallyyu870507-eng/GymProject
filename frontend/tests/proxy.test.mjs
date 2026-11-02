import assert from 'node:assert/strict'
import { test } from 'node:test'
import configuration from '../vite.config.js'

const { server } = configuration({ mode: 'test' })
const matching = url => Object.entries(server.proxy).filter(([key]) => key.startsWith('^') ? new RegExp(key).test(url) : url.startsWith(key))

test('browser feature routes do not collide with backend proxy paths', () => {
  for (const url of ['/coaches', '/courses', '/schedule', '/members', '/students', '/my-bookings', '/book-course', '/attendance', '/renewal/1']) {
    assert.equal(matching(url).length, 0, url)
  }
})
test('all four feature API families reach the shared backend', () => {
  for (const url of ['/api/user', '/api/coaches', '/api/coach/attendance', '/admin/schedules/day?date=2026-10-28', '/coaches/dashboard?date=2026-10-28', '/coaches/schedules', '/coaches/7/coach-cancel', '/booking/7/reschedule', '/members/courses/7/available-dates', '/login?error=invalid', '/logout']) {
    assert.equal(matching(url).length, 1, url)
  }
})
test('login GET always renders React, including fetch redirects and missing Accept', () => {
  const proxy = matching('/login')[0][1]
  for (const accept of ['text/html', '*/*', 'application/json', undefined]) {
    for (const url of ['/login', '/login?error=invalid']) {
      assert.equal(proxy.bypass({ method: 'GET', url, headers: { accept } }), '/index.html')
    }
  }
})
test('login HEAD resolves to the same React entry', () => {
  const proxy = matching('/login')[0][1]
  assert.equal(proxy.bypass({ method: 'HEAD', url: '/login', headers: {} }), '/index.html')
})
test('login and logout POSTs still reach the backend', () => {
  const proxy = matching('/login')[0][1]
  assert.equal(proxy.bypass({ method: 'POST', url: '/login', headers: { accept: 'text/html' } }), undefined)
  assert.equal(matching('/logout')[0][1].bypass({ method: 'POST', url: '/logout', headers: {} }), undefined)
})
