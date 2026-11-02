import { sessionFetch } from '../sessionFetch.js'
import type {
    AttendanceDetailResponse,
    AttendanceListResponse,
    AttendanceUpdateRequest
} from "../types/Attendance";

// ========================================
// GET /api/coach/attendance?date=YYYY-MM-DD
// 取得指定日期出席工作台
// ========================================

export async function getAttendanceList(
    date: string
): Promise<AttendanceListResponse> {

    const response = await sessionFetch(
        `/api/coach/attendance?date=${encodeURIComponent(date)}`,
        { credentials: "include" }
    );

    if (!response.ok) {
        throw new Error(
            `取得出席資料失敗：${response.status}`
        );
    }

    return response.json();
}


// ========================================
// GET /api/coach/attendance/{bookingId}
// 取得單一 Booking 的出席明細
// ========================================

export async function getAttendanceDetail(
    bookingId: number
): Promise<AttendanceDetailResponse> {

    const response = await sessionFetch(
        `/api/coach/attendance/${bookingId}`,
        { credentials: "include" }
    );

    if (!response.ok) {
        throw new Error(
            `取得出席明細失敗：${response.status}`
        );
    }

    return response.json();
}

// ========================================
// PUT /api/coach/attendance/{bookingId}
// 更新出席狀態、備註、訓練重點與 InBody
// ========================================

export async function updateAttendance(
    bookingId: number,
    request: AttendanceUpdateRequest
): Promise<AttendanceDetailResponse> {

    const response = await sessionFetch(
        `/api/coach/attendance/${bookingId}`,
        {
            method: "PUT",
            credentials: "include",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify(request)
        }
    );

    if (!response.ok) {
        throw new Error(
            `更新出席資料失敗：${response.status}`
        );
    }

    return response.json();
}
