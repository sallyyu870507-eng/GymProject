import assert from 'node:assert/strict'
import { afterEach, test } from 'node:test'
import { sessionFetch } from '../src/sessionFetch.js'

const originalFetch = globalThis.fetch
afterEach(() => { globalThis.fetch = originalFetch; delete globalThis.window })
test('feature APIs retain session cookies and JSON write payloads', async () => {
  globalThis.fetch = async (url, options) => {
    assert.equal(url, '/booking/7/cancel')
    assert.equal(options.credentials, 'include')
    assert.equal(options.method, 'PUT')
    assert.equal(options.body, '{"reason":"test"}')
    return new Response('{}', { headers: { 'Content-Type': 'application/json' } })
  }
  assert.equal((await sessionFetch('/booking/7/cancel', { method: 'PUT', body: '{"reason":"test"}' })).status, 200)
})
test('401 informs the common login screen without consuming the response', async () => {
  const events = []
  globalThis.window = { dispatchEvent: event => events.push(event.type) }
  globalThis.fetch = async () => new Response('{"message":"expired"}', { status: 401 })
  const response = await sessionFetch('/api/coach/renewal')
  assert.deepEqual(events, ['gym:session-expired'])
  assert.equal((await response.json()).message, 'expired')
})
test('an initial signed-out user check does not display a session-expired warning', async () => {
  const events = []
  globalThis.window = { dispatchEvent: event => events.push(event.type) }
  globalThis.fetch = async () => new Response('{}', { status: 401 })
  await sessionFetch('/api/user')
  assert.deepEqual(events, [])
})
test('legacy booking API login redirects also expire the common session', async () => {
  const events = []
  globalThis.window = { dispatchEvent: event => events.push(event.type) }
  globalThis.fetch = async () => ({ status: 200, redirected: true, url: 'http://localhost:5173/login?error=invalid' })
  await sessionFetch('/booking/my')
  assert.deepEqual(events, ['gym:session-expired'])
})
