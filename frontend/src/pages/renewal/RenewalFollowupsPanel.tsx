import { useEffect, useState } from "react";
import { getRenewalFollowups, RenewalApiError } from "../../services/renewalService";
import type { FollowupPageResponse, FollowupRecord } from "../../types/Renewal";
import "./RenewalFollowupsPanel.css";

const contactMethods: Record<string, string> = {
    PHONE: "電話", MESSAGE: "訊息", IN_PERSON: "當面", OTHER: "其他",
};
const outcomes: Record<string, string> = {
    NO_RESPONSE: "尚未取得回應", CONSIDERING: "考慮中", AGREED: "同意續約", DECLINED: "無意願",
};

function formatContactParts(value: string | null) {
    if (!value) return { date: "時間未記錄", time: "—", weekday: "" };
    // API LocalDateTime is Taipei local time without an offset; avoid Date parsing/UTC conversion.
    const match = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(value);
    if (!match) return { date: "時間未記錄", time: "—", weekday: "" };
    const [, yearText, monthText, dayText, hour, minute] = match;
    const localDate = new Date(Number(yearText), Number(monthText) - 1, Number(dayText));
    const weekday = new Intl.DateTimeFormat("zh-TW", { weekday: "short" }).format(localDate);
    return {
        date: `${yearText}/${monthText}/${dayText}`,
        time: `${hour}:${minute}`,
        weekday,
    };
}

function getErrorText(error: unknown) {
    if (error instanceof RenewalApiError) {
        if (error.status === 401) return "登入狀態已失效，請重新登入後再查看。";
        if (error.status === 403) return "目前帳號沒有權限查看此方案的跟進紀錄。";
        if (error.status === 404) return "找不到此方案或跟進紀錄。";
    }
    return "跟進紀錄載入失敗，請重試。";
}

type Props = {
    memberCourseId: number;
    page: number;
    onPageChange: (page: number) => void;
    onRefreshFailed?: (failed: boolean) => void;
    onEdit?: (followupId: number) => void;
};

export default function RenewalFollowupsPanel({ memberCourseId, page, onPageChange, onRefreshFailed, onEdit }: Props) {
    const [data, setData] = useState<FollowupPageResponse | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<unknown>(null);
    const [attempt, setAttempt] = useState(0);

    useEffect(() => {
        const controller = new AbortController();
        setData(null);
        setError(null);
        setLoading(true);
        onRefreshFailed?.(false);
        void getRenewalFollowups(memberCourseId, page, controller.signal)
            .then((result) => {
                if (!controller.signal.aborted) {
                    setData(result);
                    onRefreshFailed?.(false);
                }
            })
            .catch((requestError: unknown) => {
                if (!controller.signal.aborted) {
                    console.error("載入跟進紀錄失敗：", requestError);
                    setError(requestError);
                    onRefreshFailed?.(true);
                }
            })
            .finally(() => { if (!controller.signal.aborted) setLoading(false); });
        return () => controller.abort();
    }, [memberCourseId, page, attempt, onRefreshFailed]);

    useEffect(() => {
        if (data && data.page.number !== page) onPageChange(data.page.number);
    }, [data, onPageChange, page]);

    return (
        <section className="renewal-followups-panel" aria-label="跟進紀錄">
            <div className="renewal-followups-heading">
                <h2 className="renewal-section-heading">跟進紀錄</h2>
                <span>{loading ? "載入中…" : data ? `${data.page.totalElements} 筆` : ""}</span>
            </div>

            {loading && <div className="renewal-followups-loading" role="status" aria-label="跟進紀錄載入中">
                {[0, 1, 2].map((item) => <div className="renewal-followup-skeleton" key={item} />)}
            </div>}

            {!loading && error !== null && <div className="renewal-followups-state renewal-followups-error" role="alert">
                <p>{getErrorText(error)}</p>
                <button type="button" onClick={() => setAttempt((value) => value + 1)}>重試</button>
            </div>}

            {!loading && !error && data && data.page.totalElements === 0 && (
                <div className="renewal-followups-state">此方案尚無跟進紀錄</div>
            )}

            {!loading && !error && data && data.page.totalElements > 0 && <>
                <ol className="renewal-followup-timeline">
                    {data.items.map((record) => <FollowupCard key={record.followupId} record={record} onEdit={onEdit} />)}
                </ol>
                <div className="renewal-followups-pagination">
                    <span>共 {data.page.totalElements} 筆・每頁 {data.page.size} 筆</span>
                    <button type="button" disabled={!data.page.hasPrevious || loading} onClick={() => onPageChange(data.page.number - 1)}>上一頁</button>
                    <span>第 {data.page.number} 頁{data.page.totalPages > 0 ? `／共 ${data.page.totalPages} 頁` : ""}</span>
                    <button type="button" disabled={!data.page.hasNext || loading} onClick={() => onPageChange(data.page.number + 1)}>下一頁</button>
                </div>
            </>}

            <p className="renewal-followups-note">本頁僅顯示目前方案的跟進紀錄；同意續約不代表已完成購課。</p>
        </section>
    );
}

function FollowupCard({ record, onEdit }: { record: FollowupRecord; onEdit?: (followupId: number) => void }) {
    const method = record.contactMethod
        ? contactMethods[record.contactMethod] ?? `未知方式（${record.contactMethod}）`
        : "未設定";
    const outcome = record.status
        ? outcomes[record.status] ?? `未知狀態（${record.status}）`
        : "未設定";
    const note = record.note?.trim() ? record.note : null;

    const contactTime = formatContactParts(record.createdDate);

    return <li className="renewal-followup-entry">
        <span className="renewal-followup-timeline-dot" aria-hidden="true" />
        <time className="renewal-followup-time">
            <strong>{contactTime.date}</strong>
            <span>{contactTime.time}</span>
            {contactTime.weekday && <small>（{contactTime.weekday}）</small>}
        </time>
        <article className="renewal-followup-card">
            <div className="renewal-followup-metadata">
                <span className={`renewal-followup-chip renewal-followup-method renewal-followup-method-${record.contactMethod?.toLowerCase() || "unknown"}`}>{method}</span>
                <span className={`renewal-followup-chip renewal-followup-outcome renewal-followup-outcome-${record.status?.toLowerCase() || "unknown"}`}>{outcome}</span>
                <span className="renewal-followup-chip renewal-followup-coach">{record.coachName || "—"}</span>
                <button type="button" onClick={() => onEdit?.(record.followupId)} disabled={!onEdit}>編輯</button>
            </div>
            <div className="renewal-followup-note">
                <strong>聯繫內容</strong>
                <p>{note ?? "—"}</p>
            </div>
        </article>
    </li>;
}
