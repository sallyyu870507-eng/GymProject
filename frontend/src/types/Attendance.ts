/*
把後端JSON翻譯成 TypeScript 看得懂的資料型別
 */

// ==============================
// 共用狀態
// ==============================

export type AttendanceStatus =
    | "PENDING"
    | "PRESENT"
    | "LEAVE"
    | "ABSENT";


// PUT 不允許送 PENDING
export type AttendanceUpdateStatus =
    | "PRESENT"
    | "LEAVE"
    | "ABSENT";


// ==============================
// GET /api/attendance?date=...
// Attendance List
// ==============================

export interface AttendanceSummary {
    totalClasses: number;
    pending: number;
    present: number;
    leave: number;
    absent: number;
    cancelled: number;
}

export interface AttendanceCard {
    bookingId: number;
    scheduleId: number;

    startTime: string;
    endTime: string;

    memberCourseId: number;
    memberId: number;
    memberName: string;
    avatarUrl: string | null;

    courseName: string;
    remainingSessions: number;

    bookingStatus: string;
    attendanceStatus: AttendanceStatus;
}

export interface AttendanceListResponse {
    date: string;
    summary: AttendanceSummary;
    classes: AttendanceCard[];
}


// ==============================
// InBody
// ==============================

// PUT 時送給後端
export interface InBodyRequest {
    weight: number;
    bodyFatPct: number;
    muscleMass: number;
}

// GET Detail 時後端回傳
export interface InBodyResponse {
    recordDate: string;
    weight: number;
    bodyFatPct: number;
    muscleMass: number;
}


// ==============================
// GET /api/attendance/{bookingId}
// Attendance Detail
// ==============================

export interface AttendanceClassInfo {
    date: string;
    startTime: string;
    endTime: string;
}

export interface AttendanceMember {
    memberId: number;
    name: string;
    gender: string;
    phone: string;
    email: string;
    avatarUrl: string | null;
}

export interface AttendanceCourse {
    memberCourseId: number;
    courseName: string;
    totalSessions: number;
    remainingSessions: number;
    lastPresentDate: string | null;
}

export interface AttendanceInfo {
    attendanceId: number | null;
    status: AttendanceStatus;
    checkInTime: string | null;
    workoutFocus: string | null;
    note: string | null;
    inBody: InBodyResponse | null;
}

export interface AttendanceHistory {
    date: string;
    status: AttendanceStatus;
    workoutFocus: string | null;
    note: string | null;
}

export interface AttendanceDetailResponse {
    bookingId: number;

    classInfo: AttendanceClassInfo;

    member: AttendanceMember;

    course: AttendanceCourse;

    attendance: AttendanceInfo;

    history: AttendanceHistory[];
}


// ==============================
// PUT /api/attendance/{bookingId}
// ==============================

export interface AttendanceUpdateRequest {
    status: AttendanceUpdateStatus;

    workoutFocus?: string | null;

    note?: string | null;

    inBody?: InBodyRequest | null;
}