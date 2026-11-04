import { sessionFetch } from "../sessionFetch.js";

export function buildRenewalInBodyRequest(memberCourseId, page, signal) {
    const params = new URLSearchParams({
        page: String(page),
        size: "5",
        scope: "COACH_MEMBER",
    });
    return {
        url: `/api/coach/renewal/${memberCourseId}/inbody?${params.toString()}`,
        options: {
            method: "GET",
            credentials: "include",
            signal,
            headers: { Accept: "application/json" },
        },
    };
}

export async function requestRenewalInBody(memberCourseId, page, signal) {
    const { url, options } = buildRenewalInBodyRequest(memberCourseId, page, signal);
    return sessionFetch(url, options);
}
