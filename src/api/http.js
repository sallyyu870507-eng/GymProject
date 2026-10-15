import { API_BASE } from "../config.js";

export class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

// 後端沒有設定 include-message 時，權限錯誤（RuntimeException）會變成沒有內容的 500
const friendly = status =>
  [401, 403, 500].includes(status) ? "請先登入，或目前身分沒有這項權限（登入可能已逾時）" : `請求失敗 (${status})`;

// 所有請求統一從這裡出去：credentials 帶 Session Cookie、回應可能是 JSON 或純文字（例如 /booking 的錯誤訊息）
export async function http(path, { method = "GET", body } = {}) {
  let res;
  try {
    res = await fetch(API_BASE + path, {
      method,
      credentials: "include",
      headers: body ? { "Content-Type": "application/json" } : undefined,
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw new ApiError("無法連上後端，請確認後端已啟動", 0);
  }

  const text = await res.text();
  let data = text;
  try { data = text ? JSON.parse(text) : null; } catch { /* 純文字 */ }

  if (!res.ok) {
    // Vite 轉發不到後端時會回 500，內容以此開頭
    if (typeof data === "string" && data.startsWith("Error occurred while trying to proxy"))
      throw new ApiError("無法連上後端（localhost:8080），請確認後端已啟動", 502);
    const msg = typeof data === "string" && data ? data : data?.message || friendly(res.status);
    throw new ApiError(msg, res.status);
  }
  return data;
}
