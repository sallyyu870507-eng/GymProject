/**
 * 所有 API 請求都經過這裡：
 * - 自動帶 Session Cookie（credentials: 'include'）
 * - 自動把 JSON / 純文字回應解析好
 * - 錯誤統一變成 ApiError，畫面直接顯示 error.message
 * - 401 未登入時自動導回登入頁
 */

export class ApiError extends Error {
  readonly status: number;
  readonly body?: unknown;

  constructor(status: number, message: string, body?: unknown) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.body = body;
  }

  /** DTO 驗證失敗時（GlobalExceptionHandler 400）各欄位的錯誤訊息，例如 { phone: '手機號碼格式錯誤' } */
  get fieldErrors(): Record<string, string> {
    const errors = (this.body as { errors?: unknown } | undefined)?.errors;
    return errors && typeof errors === 'object' ? (errors as Record<string, string>) : {};
  }
}

/** 從任何錯誤取出欄位錯誤（不是 ApiError 就回空物件） */
export const fieldErrorsOf = (err: unknown) => (err instanceof ApiError ? err.fieldErrors : {});

const BASE_URL = (import.meta.env.VITE_API_BASE_URL ?? '').replace(/\/$/, '');

export type Query = Record<string, string | number | boolean | null | undefined>;

export function buildUrl(path: string, query?: Query): string {
  const qs = new URLSearchParams();
  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value !== undefined && value !== null) qs.append(key, String(value));
    }
  }
  const search = qs.toString();
  return `${BASE_URL}${path}${search ? `?${search}` : ''}`;
}

let unauthorizedHandler: (() => void) | undefined;

/** AuthProvider 會註冊：收到 401 就清掉登入狀態並回登入頁 */
export function setUnauthorizedHandler(handler?: () => void) {
  unauthorizedHandler = handler;
}

const DEFAULT_MESSAGES: Record<number, string> = {
  400: '送出的資料有誤',
  409: '資料重複，請更換後再試',
  401: '尚未登入或登入已逾時',
  403: '沒有權限執行這個動作',
  404: '找不到這個 API，請確認網址',
  500: '伺服器發生錯誤，請查看後端 Console',
};

function parseBody(text: string): unknown {
  if (!text) return undefined;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

/**
 * ResponseStatusException 的 getMessage() 長這樣：409 CONFLICT "帳號已被使用"
 * 只取引號裡給人看的那段。
 */
function cleanMessage(message: string): string {
  const m = message.match(/^\d{3}\s+[A-Z_ ]+\s+"(.*)"$/s);
  return (m ? m[1] : message).trim();
}

/**
 * 後端錯誤的幾種樣子：
 * - 純文字（規格書 POST /booking）
 * - { success:false, message }（GlobalExceptionHandler）
 * - { success:false, errors:{ 欄位: 訊息 } }（DTO 驗證失敗）
 * - Spring 預設錯誤 JSON 或空內容（LoginInterceptor 的 401 / 403）
 */
function messageOf(body: unknown, status: number): string {
  if (typeof body === 'string' && body.trim() && !body.trimStart().startsWith('<')) {
    return cleanMessage(body);
  }
  if (body && typeof body === 'object') {
    const b = body as Record<string, unknown>;
    if (typeof b.message === 'string' && b.message.trim()) return cleanMessage(b.message);
    if (b.errors && typeof b.errors === 'object') {
      const list = Object.values(b.errors as Record<string, unknown>).filter((v) => typeof v === 'string');
      if (list.length) return list.join('、');
    }
  }
  return DEFAULT_MESSAGES[status] ?? `伺服器回應錯誤（HTTP ${status}）`;
}

interface RequestOptions {
  query?: Query;
  json?: unknown;
  form?: Record<string, string>;
  signal?: AbortSignal;
}

export async function request<T>(method: string, path: string, opts: RequestOptions = {}): Promise<T> {
  const headers: Record<string, string> = { Accept: 'application/json' };
  let body: BodyInit | undefined;

  if (opts.json !== undefined) {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(opts.json);
  } else if (opts.form) {
    body = new URLSearchParams(opts.form);
  }

  let res: Response;
  try {
    res = await fetch(buildUrl(path, opts.query), {
      method,
      headers,
      body,
      credentials: 'include',
      signal: opts.signal,
    });
  } catch (err) {
    if ((err as Error).name === 'AbortError') throw err;
    throw new ApiError(0, '無法連線到後端，請確認 Spring Boot 已啟動');
  }

  const data = parseBody(await res.text());

  if (!res.ok) {
    if (res.status === 401) unauthorizedHandler?.();
    throw new ApiError(res.status, messageOf(data, res.status), data);
  }
  return data as T;
}

export const http = {
  get: <T>(path: string, query?: Query, signal?: AbortSignal) =>
    request<T>('GET', path, { query, signal }),
  post: <T>(path: string, json?: unknown, signal?: AbortSignal) =>
    request<T>('POST', path, { json, signal }),
  put: <T>(path: string, json?: unknown, signal?: AbortSignal) =>
    request<T>('PUT', path, { json, signal }),
  patch: <T>(path: string, json?: unknown, signal?: AbortSignal) =>
    request<T>('PATCH', path, { json, signal }),
  del: <T>(path: string, signal?: AbortSignal) => request<T>('DELETE', path, { signal }),
};
