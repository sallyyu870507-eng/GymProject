// All feature APIs use the same server session and expiration handling.
export async function sessionFetch(url, options = {}) {
  const response = await fetch(url, { credentials: 'include', ...options })
  const redirectedToLogin = response.redirected && /\/login(?:\.html)?(?:\?|$)/.test(response.url)
  if ((response.status === 401 || redirectedToLogin) && url !== '/api/user' && url !== '/logout' && typeof window !== 'undefined') {
    window.dispatchEvent(new Event('gym:session-expired'))
  }
  return response
}
