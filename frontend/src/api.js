export class ApiError extends Error {
  constructor(message, status) { super(message); this.status = status }
}

/*提供 request()，讓其他元件統一透過它呼叫 API，集中處理*/
export async function request(path, options = {}) {
  let response
  try {
    response = await fetch(path, {
      credentials: 'include', ...options,
      headers: { ...(options.body ? { 'Content-Type': 'application/json' } : {}), ...options.headers }
    })
  } catch (error) {
    if (error.name === 'AbortError') throw error
    throw new ApiError('無法連線，請確認 Spring Boot 已啟動。', 0)
  }
  const isJson = response.headers.get('content-type')?.includes('application/json')
  const data = isJson ? await response.json() : null
  if (!response.ok || data?.success === false) {
    const message = response.status === 401 ? '尚未登入或登入已過期，請重新登入。'
      : response.status === 403 ? '你沒有執行這項操作的權限。'
      : data?.errors ? Object.values(data.errors).join('、')
      : data?.message || `請求失敗（${response.status}），請確認後端服務。`
    throw new ApiError(message, response.status)
  }
  if (!isJson) throw new ApiError('後端未回傳 JSON，請確認登入狀態與服務設定。', response.status)
  return data
}
