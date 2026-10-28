import type {
    RenewalCategory,
    RenewalFollowupStatus,
    RenewalScope,
    RenewalWorkbenchResponse,
    RenewalOverviewResponse,
    FollowupPageResponse,
    FollowupRecord,
    AttendanceSummary,
    InBodyPageResponse,
    RenewalOptionsResponse,
    RenewalCreateRequest,
    RenewalCreateResponse,
} from "../types/Renewal";

export type RenewalWorkbenchQuery = {
    scope: RenewalScope;
    keyword: string;
    category: RenewalCategory;
    followupStatus: RenewalFollowupStatus;
    page: number;
    size: 10;
};

export class RenewalApiError extends Error {
    readonly status: number;

    constructor(status: number, message?: string) {
        super(message || `續約 API 請求失敗：${status}`);
        this.name = "RenewalApiError";
        this.status = status;
    }
}

export type CreateFollowupRequest = {
    createdDate: string;
    contactMethod: string;
    status: string;
    note: string | null;
};

export async function createRenewalFollowup(
    memberCourseId: number,
    request: CreateFollowupRequest,
    idempotencyKey: string,
): Promise<FollowupRecord> {
    const response = await fetch(`/api/coach/renewal/${memberCourseId}/followups`, {
        method: "POST",
        credentials: "include",
        headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
            "Idempotency-Key": idempotencyKey,
        },
        body: JSON.stringify(request),
    });

    if (!response.ok) {
        let message: string | undefined;
        try {
            const errorBody = (await response.json()) as { message?: unknown };
            if (typeof errorBody.message === "string") message = errorBody.message;
        } catch {
            // Keep the HTTP status when the server response has no JSON error body.
        }
        throw new RenewalApiError(response.status, message);
    }

    return (await response.json()) as FollowupRecord;
}

export type UpdateFollowupRequest = CreateFollowupRequest & {
    contactTimeChanged: boolean;
};

export async function getRenewalFollowup(
    memberCourseId: number,
    followupId: number,
    signal?: AbortSignal,
): Promise<FollowupRecord> {
    const response = await fetch(`/api/coach/renewal/${memberCourseId}/followups/${followupId}`, {
        method: "GET",
        credentials: "include",
        signal,
        headers: { Accept: "application/json" },
    });
    if (!response.ok) {
        throw await toRenewalApiError(response);
    }
    return (await response.json()) as FollowupRecord;
}

export async function updateRenewalFollowup(
    memberCourseId: number,
    followupId: number,
    request: UpdateFollowupRequest,
): Promise<FollowupRecord> {
    const response = await fetch(`/api/coach/renewal/${memberCourseId}/followups/${followupId}`, {
        method: "PUT",
        credentials: "include",
        headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
        },
        body: JSON.stringify(request),
    });
    if (!response.ok) {
        throw await toRenewalApiError(response);
    }
    return (await response.json()) as FollowupRecord;
}

async function toRenewalApiError(response: Response): Promise<RenewalApiError> {
    let message: string | undefined;
    try {
        const errorBody = (await response.json()) as { message?: unknown };
        if (typeof errorBody.message === "string") message = errorBody.message;
    } catch {
        // Keep the status if the API does not return a JSON error body.
    }
    return new RenewalApiError(response.status, message);
}

export async function getRenewalWorkbench(
    query: RenewalWorkbenchQuery,
    signal?: AbortSignal,
): Promise<RenewalWorkbenchResponse> {
    const params = new URLSearchParams({
        scope: query.scope,
        keyword: query.keyword,
        category: query.category,
        followupStatus: query.followupStatus,
        page: String(query.page),
        size: String(query.size),
    });

    const response = await fetch(`/api/coach/renewal?${params.toString()}`, {
        method: "GET",
        credentials: "include",
        signal,
        headers: { Accept: "application/json" },
    });

    if (!response.ok) {
        throw new RenewalApiError(response.status);
    }

    return (await response.json()) as RenewalWorkbenchResponse;
}

export async function getRenewalOverview(
    memberCourseId: number,
    signal?: AbortSignal,
): Promise<RenewalOverviewResponse> {
    const response = await fetch(`/api/coach/renewal/${memberCourseId}`, {
        method: "GET",
        credentials: "include",
        signal,
        headers: { Accept: "application/json" },
    });

    if (!response.ok) {
        throw new RenewalApiError(response.status);
    }

    return (await response.json()) as RenewalOverviewResponse;
}

export async function getRenewalFollowups(
    memberCourseId: number,
    page: number,
    signal?: AbortSignal,
): Promise<FollowupPageResponse> {
    const params = new URLSearchParams({ page: String(page), size: "10" });
    const response = await fetch(`/api/coach/renewal/${memberCourseId}/followups?${params.toString()}`, {
        method: "GET",
        credentials: "include",
        signal,
        headers: { Accept: "application/json" },
    });

    if (!response.ok) {
        throw new RenewalApiError(response.status);
    }

    return (await response.json()) as FollowupPageResponse;
}

export async function getRenewalAttendanceSummary(
    memberCourseId: number,
    signal?: AbortSignal,
): Promise<AttendanceSummary> {
    const response = await fetch(`/api/coach/renewal/${memberCourseId}/attendance-summary`, {
        method: "GET", credentials: "include", signal, headers: { Accept: "application/json" },
    });
    if (!response.ok) throw await toRenewalApiError(response);
    return (await response.json()) as AttendanceSummary;
}

export async function getRenewalInBody(
    memberCourseId: number,
    page: number,
    signal?: AbortSignal,
): Promise<InBodyPageResponse> {
    const params = new URLSearchParams({ page: String(page), size: "5" });
    const response = await fetch(`/api/coach/renewal/${memberCourseId}/inbody?${params.toString()}`, {
        method: "GET", credentials: "include", signal, headers: { Accept: "application/json" },
    });
    if (!response.ok) throw await toRenewalApiError(response);
    return (await response.json()) as InBodyPageResponse;
}

export async function getRenewalOptions(
    memberCourseId: number,
    signal?: AbortSignal,
): Promise<RenewalOptionsResponse> {
    const response = await fetch(`/api/coach/renewal/${memberCourseId}/renewal-options`, {
        method: "GET", credentials: "include", signal, headers: { Accept: "application/json" },
    });
    if (!response.ok) throw await toRenewalApiError(response);
    return (await response.json()) as RenewalOptionsResponse;
}

export async function createRenewal(
    memberCourseId: number,
    request: RenewalCreateRequest,
    idempotencyKey: string,
): Promise<RenewalCreateResponse> {
    const response = await fetch(`/api/coach/renewal/${memberCourseId}/renewals`, {
        method: "POST", credentials: "include",
        headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
            "Idempotency-Key": idempotencyKey,
        },
        body: JSON.stringify(request),
    });
    if (!response.ok) throw await toRenewalApiError(response);
    return (await response.json()) as RenewalCreateResponse;
}
