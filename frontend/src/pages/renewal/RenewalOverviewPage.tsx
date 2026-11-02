import { useEffect, useLayoutEffect, useState, type ReactNode } from "react";
import { useNavigate, useParams, useLocation } from "react-router";
import { getRenewalOverview, RenewalApiError } from "../../services/renewalService";
import type { RenewalOverviewResponse, RenewalTag } from "../../types/Renewal";
import RenewalFollowupsPanel from "./RenewalFollowupsPanel";
import RenewalAttendanceInBodyPanel from "./RenewalAttendanceInBodyPanel";
import RenewalPlanIdentity from "../../components/renewal/RenewalPlanIdentity";
import "../../components/renewal/RenewalContentContainer.css";
import "./RenewalOverviewPage.css";

type RestoreFilters = {
    scope: "TRACKING" | "ALL_PLANS";
    keyword: string;
    category: "ALL" | "HIGH_PRIORITY" | "UPCOMING" | "LONG_ABSENT" | "COMPLETED";
    followupStatus: "ALL" | "NOT_CONTACTED" | "NO_RESPONSE" | "CONSIDERING" | "AGREED" | "DECLINED";
    page: number;
    requestVersion: number;
    keywordDraft: string;
};
type DetailsNavigationState = { restoreFilters?: RestoreFilters; returnScrollY?: number; fromDetailsSearch?: string; editReturnSearch?: string; followupCreated?: boolean; followupUpdated?: boolean; renewalCreated?: boolean; renewalResult?: { newMemberCourseId: number; courseName: string; addedSessions: number; purchaseDate: string }; renewalRefreshFailed?: boolean };

const tagLabels: Record<string, string> = {
    HIGH_PRIORITY: "優先聯繫", UPCOMING: "堂數將盡", LONG_ABSENT: "久未到課", COMPLETED: "已用完",
};
const followupLabels: Record<string, string> = {
    NOT_CONTACTED: "未聯繫", NO_RESPONSE: "尚未取得回應", CONSIDERING: "考慮中", AGREED: "同意續約", DECLINED: "無意願",
};

function displayDate(value: string | null | undefined) {
    return value ? value.replaceAll("-", "/") : "—";
}

function displayRenewalDateTime(value: string | null | undefined) {
    if (!value) return "—";
    const match = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::\d{2}(?:\.\d+)?)?$/.exec(value);
    if (!match) return "—";
    const [, yearText, monthText, dayText, hourText, minuteText] = match;
    const year = Number(yearText);
    const month = Number(monthText);
    const day = Number(dayText);
    const hour = Number(hourText);
    const minute = Number(minuteText);
    const date = new Date(0);
    date.setUTCFullYear(year, month - 1, day);
    date.setUTCHours(hour, minute, 0, 0);
    if (date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1
        || date.getUTCDate() !== day || hour > 23 || minute > 59) return "—";
    return `${yearText}/${monthText}/${dayText} ${hourText}:${minuteText}`;
}

function errorMessage(error: unknown): { title: string; body: string } {
    if (error instanceof RenewalApiError) {
        if (error.status === 401) return { title: "登入狀態已失效", body: "請重新登入後再查看方案詳情。" };
        if (error.status === 403) return { title: "無權查看此方案", body: "目前帳號沒有權限查看這筆續約與關懷資料。" };
        if (error.status === 404) return { title: "找不到此購課方案", body: "此方案可能已不存在，或目前無法查看。" };
    }
    return { title: "方案資料載入失敗", body: "請確認連線後重試。" };
}

function OverviewIcon({ name }: { name: "gender" | "phone" | "email" | "course" | "coach" | "date" | "total" | "used" | "remaining" | "attendance" | "alert" }) {
    const common = { fill: "none", stroke: "currentColor", strokeWidth: 1.8, strokeLinecap: "round" as const, strokeLinejoin: "round" as const };
    const paths: Record<typeof name, ReactNode> = {
        gender: <text x="12" y="20" textAnchor="middle" fill="currentColor" fontSize="22">♀</text>,
        phone: <path {...common} d="M5 3h3l2 5-2 1.5a14 14 0 0 0 6.5 6.5L16 14l5 2v3a2 2 0 0 1-2 2C10 21 3 14 3 5a2 2 0 0 1 2-2Z" />,
        email: <><rect {...common} x="2.5" y="4.5" width="19" height="15" rx="2" /><path {...common} d="m3.5 6 8.5 7 8.5-7" /></>,
        course: <><path {...common} d="M3 8 12 3l9 5-9 5-9-5Z" /><path {...common} d="m4 12 8 4.5 8-4.5M4 16l8 4.5 8-4.5" /></>,
        coach: <><circle {...common} cx="12" cy="7" r="4" /><path {...common} d="M4 21v-2a8 8 0 0 1 16 0v2Z" /></>,
        date: <><rect {...common} x="3" y="5" width="18" height="16" rx="2" /><path {...common} d="M16 3v4M8 3v4M3 10h18M8 14h.01M12 14h.01M16 14h.01M8 17h.01M12 17h.01" /></>,
        total: <><path {...common} d="m12 3 9 5-9 5-9-5 9-5Z" /><path {...common} d="m3 12 9 5 9-5M3 16l9 5 9-5" /></>,
        used: <><circle {...common} cx="12" cy="12" r="9" /><path {...common} d="m8 12 2.5 2.5L16 9" /></>,
        remaining: <><circle {...common} cx="12" cy="12" r="9" /><path {...common} d="M12 7v5l3 2" /></>,
        attendance: <><rect {...common} x="3" y="5" width="18" height="16" rx="2" /><path {...common} d="M16 3v4M8 3v4M3 10h18M8 14h.01M12 14h.01M16 14h.01" /></>,
        alert: <><path {...common} d="M10.3 4.3 2.8 18a2 2 0 0 0 1.8 3h14.8a2 2 0 0 0 1.8-3L13.7 4.3a2 2 0 0 0-3.4 0Z" /><path {...common} d="M12 9v4m0 4h.01" /></>,
    };
    return <svg className={`renewal-overview-icon renewal-overview-icon-${name}`} viewBox="0 0 24 24" aria-hidden="true">{paths[name]}</svg>;
}

function RenewalOverviewPage() {
    const { memberCourseId: idParam } = useParams();
    const navigate = useNavigate();
    const location = useLocation();
    const [data, setData] = useState<RenewalOverviewResponse | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<unknown>(null);
    const [attempt, setAttempt] = useState(0);
    const [followupRefreshFailed, setFollowupRefreshFailed] = useState(false);
    const validId = idParam && /^[1-9]\d*$/.test(idParam) ? Number(idParam) : null;
    const routeState = location.state as DetailsNavigationState | null;
    const query = new URLSearchParams(location.search);
    const activeTab = query.get("tab") === "followups"
        ? "followups"
        : query.get("tab") === "attendance"
            ? "attendance"
            : "overview";
    const rawFollowupPage = Number(query.get("followupPage"));
    const followupPage = Number.isSafeInteger(rawFollowupPage) && rawFollowupPage > 0 ? rawFollowupPage : 1;

    useLayoutEffect(() => {
        const pageScroller = document.scrollingElement;
        if (pageScroller) pageScroller.scrollTop = 0;
    }, [location.pathname]);

    useEffect(() => {
        if (validId === null) {
            setLoading(false);
            setError(new RenewalApiError(404));
            return;
        }
        const controller = new AbortController();
        setData(null);
        setError(null);
        setLoading(true);
        void getRenewalOverview(validId, controller.signal)
            .then((result) => {
                if (!controller.signal.aborted) {
                    setData(result);
                    if (routeState?.followupCreated || routeState?.followupUpdated || routeState?.renewalCreated) setFollowupRefreshFailed(false);
                }
            })
            .catch((requestError: unknown) => {
                if (!controller.signal.aborted) {
                    console.error("載入方案詳情失敗：", requestError);
                    setError(requestError);
                    if (routeState?.followupCreated || routeState?.followupUpdated || routeState?.renewalCreated) setFollowupRefreshFailed(true);
                }
            })
            .finally(() => { if (!controller.signal.aborted) setLoading(false); });
        return () => controller.abort();
    }, [validId, attempt]);

    function returnToWorkbench() {
        navigate("/renewal", { state: {
            restoreFilters: routeState?.restoreFilters,
            restoreScrollY: routeState?.returnScrollY,
        } });
    }

    function selectTab(tab: "overview" | "followups" | "attendance") {
        const nextQuery = new URLSearchParams(location.search);
        nextQuery.set("tab", tab);
        navigate(`${location.pathname}?${nextQuery.toString()}`, { state: location.state, preventScrollReset: true });
    }

    function setFollowupPage(page: number) {
        const nextQuery = new URLSearchParams(location.search);
        nextQuery.set("tab", "followups");
        if (page <= 1) nextQuery.delete("followupPage");
        else nextQuery.set("followupPage", String(page));
        navigate(`${location.pathname}?${nextQuery.toString()}`, { state: location.state, preventScrollReset: true });
    }

    function editFollowup(followupId: number) {
        navigate(`/renewal/${data?.memberCourseId}/followups/${followupId}/edit`, {
            state: { ...routeState, editReturnSearch: location.search },
        });
    }

    return (
        <main className="renewal-overview-page renewal-content-page">
            <div className="renewal-overview-inner renewal-content-container">
                <header className="renewal-overview-topbar">
                    <div><p className="renewal-overview-eyebrow">POWER GYM／教練工作台</p><h1 className="renewal-page-title">方案詳情</h1></div>
                </header>

                <RenewalPlanIdentity
                    plan={!loading && !error ? data : null}
                    backLabel="返回工作台"
                    onBack={returnToWorkbench}
                    actions={!loading && !error && data ? <div className="renewal-overview-actions">
                        <button
                            type="button"
                            className="renewal-overview-followup-action"
                            disabled={!data.actions.canAddFollowup}
                            title={!data.actions.canAddFollowup ? "目前無法新增跟進" : undefined}
                            onClick={() => navigate(`/renewal/${data.memberCourseId}/followups/new`, {
                                state: { ...routeState, fromDetailsSearch: location.search },
                            })}
                        >＋ <span>新增跟進</span></button>
                        <button className="renewal-overview-renew-action" type="button" disabled={!data.actions.canRenew} title={!data.actions.canRenew ? (data.actions.renewDisabledReason || "目前無法辦理續約") : undefined} onClick={() => navigate(`/renewal/${data.memberCourseId}/renewals/new`, { state: { ...routeState, fromDetailsSearch: location.search } })}>↻ <span>辦理續約</span></button>
                    </div> : undefined}
                />

                {(routeState?.followupCreated || routeState?.followupUpdated || routeState?.renewalCreated) && <div className="renewal-create-result-banner" role="status">
                    <strong>{routeState.renewalCreated ? "續約已完成。" : routeState.followupUpdated ? "跟進紀錄已更新。" : "跟進紀錄已儲存。"}</strong>
                    {routeState.renewalCreated && routeState.renewalResult && <span>已建立「{routeState.renewalResult.courseName}」新方案 #{routeState.renewalResult.newMemberCourseId}，共 {routeState.renewalResult.addedSessions} 堂，購買日 {displayDate(routeState.renewalResult.purchaseDate)}。 <a href={`/renewal/${routeState.renewalResult.newMemberCourseId}`}>查看新方案</a></span>}
                    {followupRefreshFailed && <span>{routeState.renewalCreated ? "原方案摘要刷新失敗，請重試查詢；續約已成功建立。" : "資料刷新失敗，請重試查詢；請勿重複新增。"}</span>}
                </div>}

                {loading && <div className="renewal-overview-state" role="status">方案資料載入中…</div>}
                {!loading && error !== null && (() => {
                    const message = errorMessage(error);
                    return <section className="renewal-overview-state renewal-overview-error" role="alert">
                        <h2>{message.title}</h2><p>{message.body}</p>
                        <div><button type="button" onClick={() => setAttempt((value) => value + 1)}>重試</button>
                            <button type="button" className="secondary" onClick={returnToWorkbench}>返回工作台</button></div>
                    </section>;
                })()}

                {!loading && !error && data && <>
                    <nav className="renewal-overview-tabs" aria-label="方案詳情分頁">
                        <div className="renewal-overview-tabs-list">
                            <button type="button" className={activeTab === "overview" ? "is-active" : ""} aria-current={activeTab === "overview" ? "page" : undefined} onClick={() => selectTab("overview")}>方案概況</button>
                            <button type="button" className={activeTab === "followups" ? "is-active" : ""} aria-current={activeTab === "followups" ? "page" : undefined} onClick={() => selectTab("followups")}>關懷紀錄</button>
                            <button type="button" className={activeTab === "attendance" ? "is-active" : ""} aria-current={activeTab === "attendance" ? "page" : undefined} onClick={() => selectTab("attendance")}>出席與體態</button>
                        </div>
                    </nav>

                    {activeTab === "overview" ? <>
                        <section className="renewal-overview-card renewal-overview-plan-card">
                            <h3 className="renewal-section-heading">方案概況</h3>
                            <div className="renewal-overview-plan-columns">
                                <div className="renewal-overview-plan-details">
                                    <OverviewFact icon="course" label="課程" value={data.course.courseName} />
                                    <OverviewFact icon="coach" label="教練" value={data.course.coachName} />
                                    <OverviewFact icon="date" label="購買日" value={displayDate(data.course.purchaseDate)} />
                                </div>
                                <div className="renewal-overview-plan-metrics">
                                    <OverviewMetric icon="total" label="總堂數" value={`${data.course.totalSessions} 堂`} />
                                    <OverviewMetric icon="used" label="已使用堂數" value={`${data.course.usedSessions} 堂`} />
                                    <OverviewMetric icon="remaining" label="剩餘堂數" value={`${data.course.remainingSessions} 堂`} />
                                    <OverviewMetric icon="attendance" label="最近一次上課" value={data.courseActivity?.lastPresentDate ? displayDate(data.courseActivity.lastPresentDate) : "尚未出席"} detail="同課程・同教練" />
                                </div>
                            </div>
                            <div className={`renewal-overview-reminder-strip${data.reminders.length ? " has-reminders" : ""}`}>
                                <OverviewIcon name="alert" />
                                <div>{data.reminders.length ? data.reminders.map((reminder, index) => <p key={`${reminder.type}-${index}`}><strong>{tagLabels[reminder.type] ?? reminder.type}</strong><span>{reminder.message}</span></p>) : <p className="renewal-overview-muted">目前沒有提醒</p>}</div>
                            </div>
                        </section>
                        <div className="renewal-overview-grid renewal-overview-extra-grid">
                        <section className="renewal-overview-card">
                            <h3 className="renewal-section-heading">追蹤標籤</h3>
                            <TagList tags={data.tags} />
                            <h3 className="renewal-overview-subheading renewal-section-heading">跟進狀態</h3>
                            <span className="renewal-overview-status">{data.followupStatus ? followupLabels[data.followupStatus] ?? `未知狀態（${data.followupStatus}）` : "狀態未設定"}</span>
                        </section>
                        <section className="renewal-overview-card renewal-overview-renewals">
                            <h3 className="renewal-section-heading">既有續約關聯</h3>
                            {data.outgoingRenewals.length ? <ul>{data.outgoingRenewals.map((renewal) => <li key={renewal.renewalId}>
                                <strong>已完成續約 → 新方案 #{renewal.newMemberCourseId}</strong>
                                <span>{renewal.courseName || "—"}・購買日 {displayDate(renewal.purchaseDate)}・續約日 {displayRenewalDateTime(renewal.renewalDate)}</span>
                            </li>)}</ul> : <p className="renewal-overview-muted">尚無續約紀錄</p>}
                        </section>
                        </div>
                    </> : activeTab === "followups" ? <>
                        <RenewalFollowupsPanel
                            key={`${data.memberCourseId}-${followupPage}`}
                            memberCourseId={data.memberCourseId}
                            page={followupPage}
                            onPageChange={setFollowupPage}
                            onRefreshFailed={setFollowupRefreshFailed}
                            onEdit={editFollowup}
                        />
                    </> : <>
                        <RenewalAttendanceInBodyPanel memberCourseId={data.memberCourseId} />
                    </>}
                    <p className="renewal-overview-as-of">資料基準日：{displayDate(data.asOfDate)}</p>
                </>}
            </div>
        </main>
    );
}

function OverviewFact({ icon, label, value }: { icon: "course" | "coach" | "date"; label: string; value: string | null | undefined }) {
    return <div className="renewal-overview-fact"><span className="renewal-overview-fact-icon"><OverviewIcon name={icon} /></span><div><span>{label}</span><strong>{value || "—"}</strong></div></div>;
}

function OverviewMetric({ icon, label, value, detail }: { icon: "total" | "used" | "remaining" | "attendance"; label: string; value: string; detail?: string }) {
    return <div className="renewal-overview-metric"><OverviewIcon name={icon} /><span className="renewal-overview-metric-label">{label}</span><strong>{value}</strong>{detail && <small>{detail}</small>}</div>;
}

function TagList({ tags }: { tags: RenewalTag[] }) {
    return tags.length ? <div className="renewal-overview-tags">{tags.map((tag, index) => <span key={`${tag}-${index}`}>{tagLabels[tag] ?? tag}</span>)}</div> : <p className="renewal-overview-muted">目前沒有追蹤標籤</p>;
}

export default RenewalOverviewPage;
