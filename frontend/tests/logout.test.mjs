import assert from 'node:assert/strict'
import http from 'node:http'
import { test } from 'node:test'
import { createServer } from 'vite'
import configuration from '../vite.config.js'

test('real proxy: logout redirect with Accept */* returns React instead of legacy login HTML', async t => {
  const requests = []
  const backend = http.createServer((req, res) => {
    requests.push({ method: req.method, url: req.url, cookie: req.headers.cookie })
    if (req.method === 'POST' && req.url === '/logout') {
      res.writeHead(302, { Location: '/login' })
      res.end()
    } else if (req.method === 'POST' && req.url === '/login') {
      res.writeHead(302, { Location: '/admin' })
      res.end()
    } else {
      res.writeHead(200, { 'Content-Type': 'text/html' })
      res.end('<title>FitBook-Login</title><p>legacy login must not be served</p>')
    }
  })
  t.after(() => new Promise(resolve => backend.close(resolve)))
  await new Promise(resolve => backend.listen(0, '127.0.0.1', resolve))
  const config = configuration({ mode: 'test' })
  for (const proxy of Object.values(config.server.proxy)) proxy.target = `http://127.0.0.1:${backend.address().port}`
  const vite = await createServer({ ...config, configFile: false, logLevel: 'silent', server: { ...config.server, middlewareMode: true, hmr: false } })
  t.after(() => vite.close())
  const frontend = http.createServer(vite.middlewares)
  t.after(() => new Promise(resolve => frontend.close(resolve)))
  await new Promise(resolve => frontend.listen(0, '127.0.0.1', resolve))
  const origin = `http://127.0.0.1:${frontend.address().port}`
  const response = await fetch(`${origin}/logout`, {
    method: 'POST', headers: { Accept: '*/*', Cookie: 'fixture-session=logout-test' }, signal: AbortSignal.timeout(5000),
  })
  assert.equal(response.status, 200)
  assert.equal(response.url, `${origin}/login`)
  const html = await response.text()
  assert.match(html, /\/src\/main\.jsx/)
  assert.doesNotMatch(html, /FitBook-Login/)
  assert.deepEqual(requests, [{ method: 'POST', url: '/logout', cookie: 'fixture-session=logout-test' }])
  for (const accept of ['*/*', 'text/html', 'application/json']) {
    const login = await fetch(`${origin}/login?error=invalid`, { headers: { Accept: accept }, signal: AbortSignal.timeout(5000) })
    assert.match(await login.text(), /\/src\/main\.jsx/)
  }
  const loginPost = await fetch(`${origin}/login`, { method: 'POST', redirect: 'manual', signal: AbortSignal.timeout(5000) })
  assert.equal(loginPost.status, 302)
  assert.equal(loginPost.headers.get('location'), '/admin')
  assert.equal(requests.at(-1).method, 'POST')
  assert.equal(requests.at(-1).url, '/login')
})
