import assert from 'node:assert/strict'
import { test } from 'node:test'
import { requestRenewalInBody } from '../src/services/renewalInBodyRequest.js'

test('InBody GET 將範圍與 AbortSignal 傳到實際 fetch', async () => {
  const originalFetch = globalThis.fetch
  const controller = new AbortController()
  let actualRequest
  globalThis.fetch = async (url, options) => {
    actualRequest = { url, options }
    return new Response('{"ok":true}', { status: 200, headers: { 'Content-Type': 'application/json' } })
  }

  try {
    const response = await requestRenewalInBody(43, 2, controller.signal)
    assert.equal(response.ok, true)
    assert.equal(actualRequest.url, '/api/coach/renewal/43/inbody?page=2&size=5&scope=COACH_MEMBER')
    assert.equal(actualRequest.options.signal, controller.signal)
    assert.equal(actualRequest.options.method, 'GET')
    assert.equal(actualRequest.options.credentials, 'include')
  } finally {
    globalThis.fetch = originalFetch
  }
})
