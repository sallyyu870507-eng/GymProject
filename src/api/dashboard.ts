/**
 * Dashboard 用到的後端 API（都在 GymProject 的 dashboard-only 分支）。
 * 開發時由 vite.config.ts 的 proxy 轉到 http://localhost:8080。
 */
import { useCallback, useEffect, useState } from 'react';

/* ───────────── 回傳格式（和後端的 record 欄位一樣） ───────────── */

export interface MemberProfile {
  memberid: number;
  memberno: string;
  name: string;
  gender: string;
  phone: string;
  email: string;
  birthday: string;
  avatarurl: string | null;
  status: string;
}
export interface NextClass {
  bookingid: number;
  scheduleid: number;
  classdate: string;
  starttime: string;
  endtime: string;
  coursename: string;
  coursetype: string;
  classroom: string;
  coachname: string;
}
export interface WeeklyAttendance {
  week: string;
  checkins: number;
}
export interface InBodyRecord {
  inbodyid: number;
  recorddate: string;
  /** 某次量測沒有這一項時是 null */
  weight: number | null;
  bodyfatpct: number | null;
  musclemass: number | null;
}
export interface MemberCourse {
  membercourseid: number;
  coursename: string;
  coachname: string;
  totalsessions: number;
  remainingsessions: number;
  purchasedate: string;
  status: string;
}
export interface BookingStats {
  completed: number;
  cancelled: number;
  upcoming: number;
}
export interface CoachProfile {
  coachid: number;
  coachno: string;
  name: string;
  gender: string;
  phone: string;
  email: string;
  specialty: string;
  status: string;
}
export interface ScheduleRow {
  scheduleid: number;
  coachid: number;
  coachname: string;
  classdate: string;
  starttime: string;
  endtime: string;
  status: string;
  membername: string | null;
  coursename: string | null;
}

/* ───────────── 呼叫 ───────────── */

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
  }
}

/** 後端錯誤訊息（ResponseStatusException 的 reason）沒有回傳時，用這裡的說明 */
const STATUS_TEXT: Record<number, string> = {
  401: '尚未登入或登入已失效，請重新登入',
  403: '目前登入的身分不能看這個頁面',
  404: '找不到資料',
  413: '照片太大，請換一張小一點的照片',
  415: '只接受 JPG、PNG 或 WebP 圖片',
};

async function request<T>(url: string, init?: RequestInit): Promise<T> {
  let res: Response;
  try {
    res = await fetch(url, { credentials: 'include', ...init });
  } catch {
    throw new ApiError(0, '連不到後端，請確認 Spring Boot 有啟動（http://localhost:8080）');
  }
  if (res.status === 204) return null as T;
  if (!res.ok) {
    let message = STATUS_TEXT[res.status] ?? `後端回應錯誤（${res.status}）`;
    try {
      const body = await res.json();
      if (body?.message && res.status !== 401 && res.status !== 403) message = body.message;
    } catch {
      /* 沒有 JSON 內容就用預設說明 */
    }
    throw new ApiError(res.status, message);
  }
  return res.json() as Promise<T>;
}

export const api = {
  profile: () => request<MemberProfile>('/api/member/profile'),
  nextClass: () => request<NextClass | null>('/api/member/next-class'),
  attendance: (weeks = 12) => request<WeeklyAttendance[]>(`/api/member/attendance?weeks=${weeks}`),
  inbody: () => request<InBodyRecord[]>('/api/member/inbody'),
  courses: () => request<MemberCourse[]>('/api/member/courses'),
  bookingStats: () => request<BookingStats>('/api/member/booking-stats'),
  coachProfile: () => request<CoachProfile>('/api/coach/profile'),
  mySchedule: (date: string) => request<ScheduleRow[]>(`/api/coach/schedules/mine?date=${date}`),
  uploadAvatar: (file: Blob) => {
    const form = new FormData();
    form.append('file', file, 'avatar.jpg');
    return request<{ avatarurl: string }>('/api/member/avatar', { method: 'POST', body: form });
  },
};

/* ───────────── React 用 ───────────── */

export interface Loaded<T> {
  data?: T;
  error?: ApiError;
  loading: boolean;
  reload: () => void;
}

/**
 * 載入一支 API。deps 改變（例如換日期）就重新載入；
 * 舊的請求晚回來時會被丟掉，不會蓋掉新的結果。
 * enabled 為 false 時不呼叫（顯示假資料時用）。
 */
export function useApi<T>(load: () => Promise<T>, deps: unknown[], enabled = true): Loaded<T> {
  const [state, setState] = useState<{ data?: T; error?: ApiError; loading: boolean }>({ loading: enabled });
  const [tick, setTick] = useState(0);
  const reload = useCallback(() => setTick((t) => t + 1), []);

  useEffect(() => {
    if (!enabled) return;
    let alive = true;
    setState((s) => ({ ...s, loading: true, error: undefined }));
    load().then(
      (data) => alive && setState({ data, loading: false }),
      (error) => alive && setState({ error: error instanceof ApiError ? error : new ApiError(0, String(error)), loading: false }),
    );
    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, tick, enabled]);

  return { ...state, reload };
}

/**
 * 上傳前把照片縮成最長邊 600px 的 JPEG，檔案通常只有 100 KB 上下，
 * 不會超過後端 1 MB 的上限，手機拍的大照片也能直接用。
 */
export async function shrinkImage(file: File, maxSide = 600): Promise<Blob> {
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, maxSide / Math.max(bitmap.width, bitmap.height));
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  canvas.getContext('2d')!.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close();
  return new Promise((resolve, reject) =>
    canvas.toBlob((b) => (b ? resolve(b) : reject(new Error('照片轉檔失敗'))), 'image/jpeg', 0.85),
  );
}
