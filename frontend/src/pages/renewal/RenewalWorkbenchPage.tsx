import { useEffect, useLayoutEffect, useMemo, useRef, useState, type FormEvent } from "react";
import { useLocation, useNavigate } from "react-router";

import {
    getRenewalWorkbench,
    RenewalApiError,
} from "../../services/renewalService";
import type {
    RenewalCategory,
    RenewalFollowupStatus,
    RenewalScope,
    RenewalWorkbenchItem,
    RenewalWorkbenchResponse,
} from "../../types/Renewal";
import "../../components/renewal/RenewalContentContainer.css";
import "./RenewalWorkbenchPage.css";

const categoryOptions: Array<{ value: RenewalCategory; label: string }> = [
    { value: "ALL", label: "全部" },
    { value: "HIGH_PRIORITY", label: "優先聯繫" },
    { value: "UPCOMING", label: "堂數將盡" },
    { value: "LONG_ABSENT", label: "久未到課" },
    { value: "COMPLETED", label: "已用完" },
];

const followupOptions: Array<{ value: RenewalFollowupStatus; label: string }> = [
    { value: "ALL", label: "全部" },
    { value: "NOT_CONTACTED", label: "未聯繫" },
    { value: "NO_RESPONSE", label: "尚未取得回應" },
    { value: "CONSIDERING", label: "考慮中" },
    { value: "AGREED", label: "同意續約" },
    { value: "DECLINED", label: "無意願" },
];

const categoryLabels: Record<string, string> = {
    HIGH_PRIORITY: "優先聯繫",
    UPCOMING: "堂數將盡",
    LONG_ABSENT: "久未到課",
    COMPLETED: "已用完",
};

const followupLabels: Record<string, string> = {
    NOT_CONTACTED: "未聯繫",
    NO_RESPONSE: "尚未取得回應",
    CONSIDERING: "考慮中",
    AGREED: "同意續約",
    DECLINED: "無意願",
};

type WorkbenchFilters = {
    scope: RenewalScope;
    keyword: string;
    category: RenewalCategory;
    followupStatus: RenewalFollowupStatus;
    page: number;
    requestVersion: number;
};

type RestoreFilters = Omit<WorkbenchFilters, "requestVersion"> & { keywordDraft: string };
type WorkbenchNavigationState = { restoreFilters?: RestoreFilters; restoreScrollY?: number };

function formatDate(value: string | null | undefined): string {
    return value ? value.replaceAll("-", "/") : "—";
}

function compareItems(a: RenewalWorkbenchItem, b: RenewalWorkbenchItem): number {
    const dateOrder = b.purchaseDate.localeCompare(a.purchaseDate);
    return dateOrder || b.memberCourseId - a.memberCourseId;
}

function getErrorMessage(error: unknown): string {
    if (error instanceof RenewalApiError) {
        if (error.status === 401) {
            return "登入狀態已失效，請重新登入。";
        }
        if (error.status === 403) {
            return "目前帳號沒有權限查看續約與關懷資料。";
        }
    }
    return "資料載入失敗，請重試。";
}

function getEmptyMessage(data: RenewalWorkbenchResponse, filters: WorkbenchFilters) {
    if (data.authorizedPlanCount === 0) {
        return "目前沒有可查看的購課方案";
    }

    const isUnfilteredTracking =
        filters.scope === "TRACKING" &&
        filters.keyword === "" &&
        filters.category === "ALL" &&
        filters.followupStatus === "ALL";

    if (isUnfilteredTracking && data.trackingPlanCount === 0) {
        return "目前沒有需要追蹤的方案";
    }

    return "沒有符合篩選條件的方案";
}

function RenewalWorkbenchPage() {
    const location = useLocation();
    const navigate = useNavigate();
    const restoreFilters = (location.state as WorkbenchNavigationState | null)?.restoreFilters;
    const restoreScrollY = (location.state as WorkbenchNavigationState | null)?.restoreScrollY;
    const didRestoreScroll = useRef(false);
    const [filters, setFilters] = useState<WorkbenchFilters>(() => ({
        scope: restoreFilters?.scope ?? "TRACKING",
        keyword: restoreFilters?.keyword ?? "",
        category: restoreFilters?.category ?? "ALL",
        followupStatus: restoreFilters?.followupStatus ?? "ALL",
        page: restoreFilters?.page ?? 1,
        requestVersion: 0,
    }));
    const [keywordDraft, setKeywordDraft] = useState(restoreFilters?.keywordDraft ?? "");
    const [data, setData] = useState<RenewalWorkbenchResponse | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useLayoutEffect(() => {
        if (didRestoreScroll.current || restoreScrollY === undefined || loading || (!data && !error)) return;
        didRestoreScroll.current = true;
        requestAnimationFrame(() => {
            const pageScroller = document.scrollingElement;
            if (pageScroller) pageScroller.scrollTop = restoreScrollY;
        });
    }, [data, error, loading, restoreScrollY]);

    useEffect(() => {
        const controller = new AbortController();
        setLoading(true);
        setError(null);
        setData(null);

        void getRenewalWorkbench(
            {
                scope: filters.scope,
                keyword: filters.keyword,
                category: filters.category,
                followupStatus: filters.followupStatus,
                page: filters.page,
                size: 10,
            },
            controller.signal,
        )
            .then((result) => {
                if (!controller.signal.aborted) {
                    setData(result);
                }
            })
            .catch((requestError: unknown) => {
                if (controller.signal.aborted) {
                    return;
                }
                console.error("載入續約工作台失敗：", requestError);
                setError(getErrorMessage(requestError));
            })
            .finally(() => {
                if (!controller.signal.aborted) {
                    setLoading(false);
                }
            });

        return () => controller.abort();
    }, [filters]);

    const sortedItems = useMemo(
        () => [...(data?.items ?? [])].sort(compareItems),
        [data?.items],
    );

    function updateFilters(next: Partial<WorkbenchFilters>) {
        setFilters((current) => ({ ...current, ...next }));
    }

    function submitSearch(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        updateFilters({
            keyword: keywordDraft.trim(),
            page: 1,
            requestVersion: filters.requestVersion + 1,
        });
    }

    function selectScope(scope: RenewalScope) {
        if (scope === filters.scope) {
            return;
        }
        updateFilters({
            scope,
            category: "ALL",
            followupStatus: "ALL",
            page: 1,
        });
    }

    function clearFilters() {
        setKeywordDraft("");
        updateFilters({
            keyword: "",
            category: "ALL",
            followupStatus: "ALL",
            page: 1,
            requestVersion: filters.requestVersion + 1,
        });
    }

    function selectCategoryCard(category: RenewalCategory) {
        setKeywordDraft("");
        updateFilters({
            scope: "TRACKING",
            keyword: "",
            category,
            followupStatus: "ALL",
            page: 1,
        });
    }

    function retry() {
        updateFilters({ requestVersion: filters.requestVersion + 1 });
    }

    const isEmpty = !loading && !error && data !== null && data.items.length === 0;
    const emptyMessage = data ? getEmptyMessage(data, filters) : "";

    return (
        <main className="renewal-workbench renewal-content-page">
            <div className="renewal-workbench-inner renewal-content-container">
                <header className="renewal-workbench-header">
                    <div>
                        <p className="renewal-eyebrow">POWER GYM／教練工作台</p>
                        <h1 className="renewal-page-title">續約與學員關懷工作台</h1>
                        <p className="renewal-subtitle">依剩餘堂數與出席情況，安排續約與關懷</p>
                    </div>
                </header>

                <section className="renewal-stats" aria-label="追蹤統計">
                    <StatCard
                        title="優先聯繫"
                        value={data?.counts.highPriority}
                        description="剩餘 1～5 堂，尚未完成續約"
                        icon="!"
                        tone="priority"
                        loading={loading}
                        onClick={() => selectCategoryCard("HIGH_PRIORITY")}
                    />
                    <StatCard
                        title="堂數將盡"
                        value={data?.counts.upcoming}
                        description="剩餘 6～10 堂，尚未完成續約"
                        icon="▦"
                        tone="upcoming"
                        loading={loading}
                        onClick={() => selectCategoryCard("UPCOMING")}
                    />
                    <StatCard
                        title="久未到課"
                        value={data?.counts.longAbsent}
                        description="尚有剩堂，同課程至少 14 天未出席"
                        icon="↗"
                        tone="absent"
                        loading={loading}
                        onClick={() => selectCategoryCard("LONG_ABSENT")}
                    />
                    <StatCard
                        title="已用完"
                        value={data?.counts.completed}
                        description="剩餘 0 堂，尚未完成續約"
                        icon="▱"
                        tone="completed"
                        loading={loading}
                        onClick={() => selectCategoryCard("COMPLETED")}
                    />
                </section>
                <p className="renewal-stats-note">
                    以購課方案計數；同一方案可能符合多項條件，各項數量不可直接加總。
                </p>

                <section className="renewal-list-panel" aria-label="購課方案查詢">
                    <div className="renewal-scope-row">
                        <div className="renewal-scope-switch" role="group" aria-label="查看範圍">
                            <button
                                type="button"
                                className={filters.scope === "TRACKING" ? "is-selected" : ""}
                                aria-pressed={filters.scope === "TRACKING"}
                                onClick={() => selectScope("TRACKING")}
                            >
                                全部待追蹤
                            </button>
                            <button
                                type="button"
                                className={filters.scope === "ALL_PLANS" ? "is-selected" : ""}
                                aria-pressed={filters.scope === "ALL_PLANS"}
                                onClick={() => selectScope("ALL_PLANS")}
                            >
                                所有方案
                            </button>
                        </div>
                        <p>所有方案包含有權查看的歷史與現在購課紀錄。</p>
                    </div>

                    <form className="renewal-filters" onSubmit={submitSearch}>
                        <label className="renewal-search-field">
                            <span>會員姓名</span>
                            <input
                                type="search"
                                value={keywordDraft}
                                onChange={(event) => setKeywordDraft(event.target.value)}
                                placeholder="搜尋目前範圍內的會員姓名"
                            />
                        </label>
                        <button className="renewal-search-button" type="submit">搜尋</button>

                        <label className="renewal-select-field">
                            <span>追蹤分類</span>
                            <select
                                value={filters.category}
                                onChange={(event) => updateFilters({
                                    category: event.target.value as RenewalCategory,
                                    page: 1,
                                })}
                            >
                                {categoryOptions.map((option) => (
                                    <option key={option.value} value={option.value}>{option.label}</option>
                                ))}
                            </select>
                        </label>

                        <label className="renewal-select-field">
                            <span>跟進狀態</span>
                            <select
                                value={filters.followupStatus}
                                onChange={(event) => updateFilters({
                                    followupStatus: event.target.value as RenewalFollowupStatus,
                                    page: 1,
                                })}
                            >
                                {followupOptions.map((option) => (
                                    <option key={option.value} value={option.value}>{option.label}</option>
                                ))}
                            </select>
                        </label>
                        <button className="renewal-clear-button" type="button" onClick={clearFilters}>
                            清除篩選
                        </button>
                    </form>

                    <div className="renewal-list-heading">
                        <h2 className="renewal-section-heading">{filters.scope === "TRACKING" ? "待追蹤方案" : "購課方案列表"}</h2>
                        <span>
                            {loading ? "載入中…" : data ? `共 ${data.page.totalElements} 筆` : ""}
                        </span>
                    </div>

                    {loading && (
                        <div className="renewal-state" role="status">續約與關懷資料載入中…</div>
                    )}

                    {!loading && error && (
                        <div className="renewal-state renewal-state-error" role="alert">
                            <p>{error}</p>
                            <button type="button" onClick={retry}>重試</button>
                        </div>
                    )}

                    {isEmpty && (
                        <div className="renewal-state renewal-state-empty">
                            <p>{emptyMessage}</p>
                            {emptyMessage === "目前沒有需要追蹤的方案" && (
                                <button type="button" onClick={() => selectScope("ALL_PLANS")}>
                                    查看所有方案
                                </button>
                            )}
                            {emptyMessage === "沒有符合篩選條件的方案" && (
                                <button type="button" onClick={clearFilters}>清除篩選</button>
                            )}
                        </div>
                    )}

                    {!loading && !error && data && data.items.length > 0 && (
                        <>
                            <div className="renewal-table-scroll">
                                <table className="renewal-table">
                                    <thead>
                                        <tr>
                                            <th scope="col">會員</th>
                                            <th scope="col">課程／方案編號</th>
                                            <th scope="col">購買日</th>
                                            <th scope="col">剩餘／總堂數</th>
                                            <th scope="col">同課程最後出席日</th>
                                            <th scope="col">追蹤分類</th>
                                            <th scope="col">跟進狀態</th>
                                            <th scope="col">操作</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {sortedItems.map((item) => (
                                            <WorkbenchRow
                                                key={item.memberCourseId}
                                                item={item}
                                                onOpen={() => navigate(`/renewal/${item.memberCourseId}`, {
                                                    state: {
                                                        restoreFilters: { ...filters, keywordDraft },
                                                        returnScrollY: document.scrollingElement?.scrollTop ?? window.scrollY,
                                                    },
                                                })}
                                            />
                                        ))}
                                    </tbody>
                                </table>
                            </div>

                            <div className="renewal-pagination">
                                <span>共 {data.page.totalElements} 筆／每頁 10 筆</span>
                                <button
                                    type="button"
                                    disabled={!data.page.hasPrevious || loading}
                                    onClick={() => updateFilters({ page: Math.max(1, data.page.number - 1) })}
                                >
                                    上一頁
                                </button>
                                <span>第 {data.page.number} 頁{data.page.totalPages > 0 ? `／共 ${data.page.totalPages} 頁` : ""}</span>
                                <button
                                    type="button"
                                    disabled={!data.page.hasNext || loading}
                                    onClick={() => updateFilters({ page: data.page.number + 1 })}
                                >
                                    下一頁
                                </button>
                            </div>
                        </>
                    )}
                </section>

                <footer className="renewal-workbench-notes">
                    <p>已完成續約者停止續課提醒；仍有剩堂且久未到課者持續關懷。</p>
                    <p>久未到課依同會員、同課程、同教練跨方案的最後實際出席日計算。</p>
                    <p>同意續約不代表已完成購課。</p>
                </footer>
                {data && <p className="renewal-as-of">查詢基準日：{formatDate(data.asOfDate)}</p>}
            </div>
        </main>
    );
}

type StatCardProps = {
    title: string;
    value: number | undefined;
    description: string;
    icon: string;
    tone: string;
    loading: boolean;
    onClick: () => void;
};

function StatCard({ title, value, description, icon, tone, loading, onClick }: StatCardProps) {
    return (
        <button
            type="button"
            className={`renewal-stat-card tone-${tone}`}
            onClick={onClick}
            disabled={loading}
        >
            <span className="renewal-stat-icon" aria-hidden="true">{icon}</span>
            <span className="renewal-stat-copy">
                <strong>{title}</strong>
                <span className="renewal-stat-value">{loading || value === undefined ? "—" : value}<small> 筆</small></span>
                <span className="renewal-stat-description">{description}</span>
            </span>
        </button>
    );
}

function WorkbenchRow({ item, onOpen }: { item: RenewalWorkbenchItem; onOpen: () => void }) {
    const followupLabel = item.followupStatus
        ? followupLabels[item.followupStatus] ?? `未知狀態（${item.followupStatus}）`
        : "未知狀態";

    return (
        <tr>
            <td>
                <div className="renewal-member-cell">
                    {item.avatarUrl ? (
                        <img src={item.avatarUrl} alt="" className="renewal-avatar" />
                    ) : (
                        <span className="renewal-avatar renewal-avatar-fallback" aria-hidden="true">
                            {item.name.slice(0, 1) || "?"}
                        </span>
                    )}
                    <span>{item.name || "—"}</span>
                </div>
            </td>
            <td>
                <div className="renewal-plan-cell">
                    <strong>{item.courseName || "—"} #{item.memberCourseId}</strong>
                    {item.hasRenewed && item.outgoingRenewals.length > 0 && (
                        <span>
                            {item.outgoingRenewals.map((renewal) =>
                                `已完成續約 → 新方案 #${renewal.newMemberCourseId}`
                            ).join("；")}
                        </span>
                    )}
                </div>
            </td>
            <td>{formatDate(item.purchaseDate)}</td>
            <td className="renewal-sessions">{item.remainingSessions}／{item.totalSessions}</td>
            <td>{formatDate(item.courseActivity?.lastPresentDate) === "—"
                ? "尚未出席"
                : formatDate(item.courseActivity?.lastPresentDate)}</td>
            <td>
                <div className="renewal-tags">
                    {item.tags.length > 0
                        ? item.tags.map((tag, index) => (
                            <span key={`${tag}-${index}`} className={`renewal-tag tag-${tag.toLowerCase()}`}>
                                {categoryLabels[tag] ?? tag}
                            </span>
                        ))
                        : <span className="renewal-no-tag">—</span>}
                </div>
            </td>
            <td><span className={`renewal-followup followup-${item.followupStatus?.toLowerCase() ?? "unknown"}`}>{followupLabel}</span></td>
            <td>
                <button
                    type="button"
                    className="renewal-detail-button"
                    onClick={onOpen}
                >
                    查看詳情
                </button>
            </td>
        </tr>
    );
}

export default RenewalWorkbenchPage;
