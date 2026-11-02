import { useEffect, useRef, useState } from "react";
import { useLocation, useNavigate } from "react-router";
import { getRenewalAttendanceSummary, getRenewalInBody, RenewalApiError } from "../../services/renewalService";
import type { AttendanceSummary, InBodyPageResponse, InBodyTrendPoint } from "../../types/Renewal";
import "./RenewalAttendanceInBodyPanel.css";

type Metric = "weight" | "bodyFatPct" | "muscleMass";
const metricLabels: Record<Metric, { label: string; unit: string }> = {
    weight: { label: "體重", unit: "kg" },
    bodyFatPct: { label: "體脂率", unit: "%" },
    muscleMass: { label: "肌肉量", unit: "kg" },
};
function dateLabel(value: string | null) { return value ? value.replaceAll("-", "/") : "日期未記錄"; }
function valueLabel(value: number | null | undefined, unit: string) { return value === null || value === undefined ? "—" : `${value.toFixed(1)} ${unit}`; }
function errorLabel(error: unknown) {
    if (error instanceof RenewalApiError) {
        if (error.status === 401) return "登入狀態已失效，請重新登入。";
        if (error.status === 403) return "目前帳號沒有權限查看此方案資料。";
        if (error.status === 404) return "找不到此購課方案。";
        return error.message || `資料載入失敗（HTTP ${error.status}）。`;
    }
    return "連線失敗，請確認網路後重試。";
}

export default function RenewalAttendanceInBodyPanel({ memberCourseId }: { memberCourseId: number }) {
    const location = useLocation();
    const navigate = useNavigate();
    const query = new URLSearchParams(location.search);
    const pageParam = Number(query.get("inbodyPage"));
    const page = Number.isSafeInteger(pageParam) && pageParam > 0 ? pageParam : 1;
    const metricParam = query.get("metric");
    const metric: Metric = metricParam === "bodyFatPct" || metricParam === "muscleMass" ? metricParam : "weight";
    const previousPlanId = useRef<number | null>(null);
    const [summary, setSummary] = useState<AttendanceSummary | null>(null);
    const [summaryLoading, setSummaryLoading] = useState(true);
    const [summaryError, setSummaryError] = useState<unknown>(null);
    const [summaryAttempt, setSummaryAttempt] = useState(0);
    const [inBody, setInBody] = useState<InBodyPageResponse | null>(null);
    const [inBodyLoading, setInBodyLoading] = useState(true);
    const [inBodyError, setInBodyError] = useState<unknown>(null);
    const [inBodyAttempt, setInBodyAttempt] = useState(0);

    useEffect(() => {
        if (previousPlanId.current !== null && previousPlanId.current !== memberCourseId) {
            const next = new URLSearchParams(location.search);
            next.delete("metric");
            next.delete("inbodyPage");
            navigate(`${location.pathname}?${next.toString()}`, { state: location.state, replace: true, preventScrollReset: true });
        }
        previousPlanId.current = memberCourseId;
    }, [memberCourseId]);

    useEffect(() => {
        const controller = new AbortController();
        setSummary(null); setSummaryError(null); setSummaryLoading(true);
        void getRenewalAttendanceSummary(memberCourseId, controller.signal)
            .then((result) => { if (!controller.signal.aborted) setSummary(result); })
            .catch((error: unknown) => { if (!controller.signal.aborted) setSummaryError(error); })
            .finally(() => { if (!controller.signal.aborted) setSummaryLoading(false); });
        return () => controller.abort();
    }, [memberCourseId, summaryAttempt]);

    useEffect(() => {
        const controller = new AbortController();
        setInBody(null); setInBodyError(null); setInBodyLoading(true);
        void getRenewalInBody(memberCourseId, page, controller.signal)
            .then((result) => {
                if (controller.signal.aborted) return;
                setInBody(result);
                if (result.page.number !== page) {
                    const next = new URLSearchParams(location.search);
                    if (result.page.number <= 1) next.delete("inbodyPage");
                    else next.set("inbodyPage", String(result.page.number));
                    navigate(`${location.pathname}?${next.toString()}`, { state: location.state, replace: true, preventScrollReset: true });
                }
            })
            .catch((error: unknown) => { if (!controller.signal.aborted) setInBodyError(error); })
            .finally(() => { if (!controller.signal.aborted) setInBodyLoading(false); });
        return () => controller.abort();
    }, [memberCourseId, page, inBodyAttempt]);

    function changeQuery(nextPage: number, nextMetric: Metric) {
        const next = new URLSearchParams(location.search);
        next.set("tab", "attendance");
        if (nextPage <= 1) next.delete("inbodyPage"); else next.set("inbodyPage", String(nextPage));
        if (nextMetric === "weight") next.delete("metric"); else next.set("metric", nextMetric);
        navigate(`${location.pathname}?${next.toString()}`, { state: location.state, preventScrollReset: true });
    }

    return <section className="renewal-attendance-inbody" aria-label="出席與體態">
        <section className="renewal-attendance-block" aria-labelledby="renewal-attendance-heading">
            <div className="renewal-attendance-section-heading"><div><h2 className="renewal-section-heading" id="renewal-attendance-heading">出席統計</h2><p>本方案</p></div></div>
            {summaryLoading && <div className="renewal-attendance-stats-skeleton" role="status">出席統計載入中…</div>}
            {!summaryLoading && summaryError !== null && <div className="renewal-attendance-error" role="alert"><p>{errorLabel(summaryError)}</p><button type="button" onClick={() => setSummaryAttempt((n) => n + 1)}>重試出席統計</button></div>}
            {!summaryLoading && summaryError === null && summary && <div className="renewal-attendance-stats">
                <Stat kind="present" label="已出席" count={summary.presentCount} unit="堂" />
                <Stat kind="leave" label="請假" count={summary.leaveCount} unit="次" />
                <Stat kind="absent" label="缺席" count={summary.absentCount} unit="次" />
            </div>}
        </section>

        <section className="renewal-inbody-block" aria-labelledby="renewal-inbody-heading">
            <div className="renewal-inbody-section-heading"><div><h2 className="renewal-section-heading" id="renewal-inbody-heading">InBody 趨勢</h2><p>資料範圍：目前方案</p></div>
                <div className="renewal-inbody-metric-tabs" role="group" aria-label="趨勢指標">
                    {(Object.keys(metricLabels) as Metric[]).map((key) => <button key={key} type="button" className={metric === key ? "is-active" : ""} aria-pressed={metric === key} onClick={() => changeQuery(page, key)}>{metricLabels[key].label}</button>)}
                </div>
            </div>
            {inBodyLoading && <div className="renewal-inbody-state" role="status">InBody 資料載入中…</div>}
            {!inBodyLoading && inBodyError !== null && <div className="renewal-attendance-error" role="alert"><p>{errorLabel(inBodyError)}</p><button type="button" onClick={() => setInBodyAttempt((n) => n + 1)}>重試 InBody 資料</button></div>}
            {!inBodyLoading && inBodyError === null && inBody && <>
                <div className="renewal-inbody-latest">
                    <h3 className="renewal-section-heading">最近量測摘要</h3>
                    {!inBody.latestRecord ? <p className="renewal-inbody-empty">尚無量測紀錄</p> : <>
                        <div className="renewal-inbody-latest-values">
                            <MetricValue label="體重" value={inBody.latestRecord.weight} unit="kg" />
                            <MetricValue label="體脂率" value={inBody.latestRecord.bodyFatPct} unit="%" />
                            <MetricValue label="肌肉量" value={inBody.latestRecord.muscleMass} unit="kg" />
                            <div className="renewal-inbody-latest-date-card"><span>最近測量日期</span><strong>{dateLabel(inBody.latestRecord.recordDate)}</strong></div>
                        </div>
                    </>}
                </div>
                <div className="renewal-inbody-chart-card">
                    <h3 className="renewal-section-heading">{metricLabels[metric].label}趨勢 <small>({metricLabels[metric].unit})</small></h3>
                    <TrendChart points={inBody.trends[metric]} unit={metricLabels[metric].unit} />
                </div>
                <div className="renewal-inbody-history">
                    <div className="renewal-inbody-history-heading"><h3 className="renewal-section-heading">最近量測紀錄</h3><span>共 {inBody.page.totalElements} 筆／每頁 {inBody.page.size} 筆</span></div>
                    {inBody.items.length === 0 ? <p className="renewal-inbody-empty">尚無量測紀錄</p> : <div className="renewal-inbody-table-scroll"><table><thead><tr><th scope="col">日期</th><th scope="col">體重（kg）</th><th scope="col">體脂率（%）</th><th scope="col">肌肉量（kg）</th></tr></thead><tbody>
                        {inBody.items.map((item) => <tr key={item.inBodyId}><td>{dateLabel(item.recordDate)}</td><td>{valueLabel(item.weight, "kg")}</td><td>{valueLabel(item.bodyFatPct, "%")}</td><td>{valueLabel(item.muscleMass, "kg")}</td></tr>)}
                    </tbody></table></div>}
                    <div className="renewal-inbody-pagination"><span>第 {inBody.page.number} 頁／共 {inBody.page.totalPages} 頁</span><button type="button" disabled={!inBody.page.hasPrevious || inBodyLoading} onClick={() => changeQuery(page - 1, metric)}>上一頁</button><button type="button" disabled={!inBody.page.hasNext || inBodyLoading} onClick={() => changeQuery(page + 1, metric)}>下一頁</button></div>
                </div>
            </>}
        </section>
        <p className="renewal-inbody-footnote">僅統計目前方案；InBody 僅顯示實際量測資料。</p>
    </section>;
}

function Stat({ kind, label, count, unit }: { kind: "present" | "leave" | "absent"; label: string; count: number; unit: string }) {
    return <article className={`renewal-attendance-stat renewal-attendance-stat-${kind}`}>
        <span className="renewal-attendance-stat-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            {kind === "present" ? <><rect x="3" y="5" width="18" height="16" rx="2" /><path d="M16 3v4M8 3v4M3 10h18M8 14h.01M12 14h.01M16 14h.01" /></> : kind === "leave" ? <><path d="M7 3h8l5 5v13H7z" /><path d="M15 3v5h5M10 13h6M10 17h6" /></> : <><circle cx="12" cy="12" r="9" /><path d="m9 9 6 6m0-6-6 6" /></>}
        </svg></span>
        <span className="renewal-attendance-stat-copy"><span>{label}</span><strong>{count}<small>{unit}</small></strong></span>
    </article>;
}
function MetricValue({ label, value, unit }: { label: string; value: number | null; unit: string }) {
    return <div><span>{label}</span><strong>{valueLabel(value, unit)}</strong></div>;
}
function TrendChart({ points, unit }: { points: InBodyTrendPoint[]; unit: string }) {
    if (!points.length) return <p className="renewal-inbody-empty">尚無此項量測資料</p>;
    const width = 760; const height = 290; const padLeft = 92; const padRight = 24; const padTop = 24; const padBottom = 46;
    const values = points.map((point) => point.value);
    const dataMin = Math.min(...values); const dataMax = Math.max(...values);
    const span = dataMax - dataMin || Math.max(Math.abs(dataMax) * 0.08, 1);
    const paddedMin = dataMin - span * 0.12; const paddedMax = dataMax + span * 0.12;
    const rawStep = (paddedMax - paddedMin) / 4;
    const magnitude = 10 ** Math.floor(Math.log10(rawStep));
    const fraction = rawStep / magnitude;
    const stepFactor = fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 2.5 ? 2.5 : fraction <= 5 ? 5 : 10;
    const step = stepFactor * magnitude;
    const axisMin = Math.floor(paddedMin / step) * step;
    const axisMax = Math.ceil(paddedMax / step) * step;
    const ticks: number[] = [];
    for (let tick = axisMin, guard = 0; tick <= axisMax + step * 0.001 && guard < 8; tick += step, guard += 1) ticks.push(tick);
    const precision = Math.min(4, Math.max(0, -Math.floor(Math.log10(step))));
    const plotWidth = width - padLeft - padRight; const plotHeight = height - padTop - padBottom;
    const yForValue = (value: number) => padTop + (axisMax - value) * plotHeight / (axisMax - axisMin);
    const xForIndex = (index: number) => points.length === 1 ? padLeft + plotWidth / 2 : padLeft + index * plotWidth / (points.length - 1);
    const coords = points.map((point, index) => ({ point, x: xForIndex(index), y: yForValue(point.value) }));
    return <div className="renewal-inbody-chart-wrap"><svg viewBox={`0 0 ${width} ${height}`} role="group" aria-label={`${unit}趨勢圖，縱軸單位 ${unit}，${points.length} 筆資料`}>
        {ticks.map((tick) => <g key={tick} className="renewal-chart-grid"><line x1={padLeft} y1={yForValue(tick)} x2={width - padRight} y2={yForValue(tick)} /><text x={padLeft - 10} y={yForValue(tick)} textAnchor="end" dominantBaseline="middle">{tick.toFixed(precision)} {unit}</text></g>)}
        <line x1={padLeft} y1={height - padBottom} x2={width - padRight} y2={height - padBottom} className="renewal-chart-axis" />
        {coords.length > 1 && <polyline points={coords.map(({ x, y }) => `${x},${y}`).join(" ")} className="renewal-chart-line" fill="none" />}
        {coords.map(({ point, x, y }) => <g key={`${point.inBodyId}-${point.attendanceId}`} tabIndex={0} role="img" aria-label={`${dateLabel(point.recordDate)}，${point.value.toFixed(1)} ${unit}`} className="renewal-chart-point"><title>{dateLabel(point.recordDate)}・{point.value.toFixed(1)} {unit}</title><circle cx={x} cy={y} r="6" /><text x={x} y={height - 14} textAnchor="middle">{dateLabel(point.recordDate).slice(5)}</text></g>)}
    </svg></div>;
}
