import { confirmDialog } from '../../notifications.js';
import { useEffect, useLayoutEffect, useRef, useState, type FormEvent } from "react";
import { useLocation, useNavigate, useOutletContext, useParams } from "react-router";
import { getRenewalFollowup, getRenewalOverview, RenewalApiError, updateRenewalFollowup } from "../../services/renewalService";
import type { FollowupRecord, RenewalOverviewResponse } from "../../types/Renewal";
import "../../components/renewal/RenewalContentContainer.css";
import "./RenewalFollowupCreatePage.css";

type LayoutContext = { setHasUnsavedChanges: (value: boolean) => void; setNavigationLocked: (value: boolean) => void };
type NavigationState = { restoreFilters?: unknown; returnScrollY?: number; editReturnSearch?: string; [key: string]: unknown };
type FormValues = { createdDate: string; contactHour: string; contactMinute: string; contactMethod: string; status: string; note: string };
type Errors = Partial<Record<keyof FormValues, string>> & { form?: string };
const methods = [["PHONE", "電話"], ["MESSAGE", "訊息"], ["IN_PERSON", "當面"], ["OTHER", "其他"]];
const statuses = [["NO_RESPONSE", "尚未取得回應"], ["CONSIDERING", "考慮中"], ["AGREED", "同意續約"], ["DECLINED", "無意願"]];
const emptyValues: FormValues = { createdDate: "", contactHour: "", contactMinute: "", contactMethod: "", status: "", note: "" };

function stripWhitespace(value: string) {
    // eslint-disable-next-line no-control-regex -- Intentionally matches Java Character.isWhitespace control characters.
    return value.replace(/^[\u0009-\u000D\u001C-\u001F\u0020\u1680\u2000-\u2006\u2008-\u200A\u2028\u2029\u205F\u3000]+|[\u0009-\u000D\u001C-\u001F\u0020\u1680\u2000-\u2006\u2008-\u200A\u2028\u2029\u205F\u3000]+$/gu, "");
}
function taipeiNow() {
    return new Intl.DateTimeFormat("sv-SE", { timeZone: "Asia/Taipei", year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", hourCycle: "h23" }).format(new Date()).replace(" ", "T");
}
function parseOriginal(record: FollowupRecord): FormValues {
    const match = /^(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2})/.exec(record.createdDate ?? "");
    return { ...emptyValues, createdDate: match?.[1] ?? "", contactHour: match?.[2] ?? "", contactMinute: match?.[3] ?? "", contactMethod: record.contactMethod ?? "", status: record.status ?? "", note: record.note ?? "" };
}
function validDateTime(value: string) {
    const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/.exec(value);
    if (!m) return false;
    const [, y, mo, d, h, mi] = m.map(Number);
    const date = new Date(Date.UTC(y, mo - 1, d, h, mi));
    return y >= 1753 && y <= 9999 && date.getUTCFullYear() === y && date.getUTCMonth() === mo - 1 && date.getUTCDate() === d && h <= 23 && mi <= 59;
}
function apiErrorText(error: unknown) {
    if (!(error instanceof RenewalApiError)) return "連線失敗，請確認連線後再儲存；目前輸入內容已保留。";
    if (error.status === 400) return error.message || "資料格式不符合規定，請檢查欄位後再儲存。";
    if (error.status === 401) return error.message || "登入狀態已失效，請重新登入。";
    if (error.status === 403) return error.message || "目前帳號沒有權限編輯此跟進紀錄。";
    if (error.status === 404) return error.message || "找不到此方案或跟進紀錄。";
    if (error.status === 409) return error.message || "紀錄已變更，請重新載入原始資料後再編輯。";
    return error.message || `儲存失敗（HTTP ${error.status}），請稍後再試。`;
}

export default function RenewalFollowupEditPage() {
    const { memberCourseId: planParam, followupId: followupParam } = useParams();
    const memberCourseId = planParam && /^[1-9]\d*$/.test(planParam) ? Number(planParam) : null;
    const followupId = followupParam && /^[1-9]\d*$/.test(followupParam) ? Number(followupParam) : null;
    const navigate = useNavigate();
    const location = useLocation();
    const routeState = location.state as NavigationState | null;
    const { setHasUnsavedChanges, setNavigationLocked } = useOutletContext<LayoutContext>();
    const [plan, setPlan] = useState<RenewalOverviewResponse | null>(null);
    const [record, setRecord] = useState<FollowupRecord | null>(null);
    const [values, setValues] = useState<FormValues>(emptyValues);
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState<unknown>(null);
    const [attempt, setAttempt] = useState(0);
    const [errors, setErrors] = useState<Errors>({});
    const [dirty, setDirty] = useState(false);
    const [saving, setSaving] = useState(false);
    const inFlight = useRef(false);

    useLayoutEffect(() => { if (document.scrollingElement) document.scrollingElement.scrollTop = 0; }, [location.pathname]);
    useEffect(() => {
        const controller = new AbortController();
        setLoading(true); setLoadError(null); setPlan(null); setRecord(null); setDirty(false); setErrors({});
        if (memberCourseId === null || followupId === null) {
            setLoadError(new RenewalApiError(404, "找不到此方案或跟進紀錄。")); setLoading(false);
            return () => controller.abort();
        }
        void Promise.all([getRenewalOverview(memberCourseId, controller.signal), getRenewalFollowup(memberCourseId, followupId, controller.signal)])
            .then(([overview, found]) => {
                if (controller.signal.aborted) return;
                setPlan(overview); setRecord(found); setValues(parseOriginal(found));
            })
            .catch((error: unknown) => { if (!controller.signal.aborted) setLoadError(error); })
            .finally(() => { if (!controller.signal.aborted) setLoading(false); });
        return () => controller.abort();
    }, [memberCourseId, followupId, attempt]);
    useEffect(() => {
        setHasUnsavedChanges(dirty); setNavigationLocked(saving);
        return () => { setHasUnsavedChanges(false); setNavigationLocked(false); };
    }, [dirty, saving, setHasUnsavedChanges, setNavigationLocked]);
    useEffect(() => {
        if (!dirty) return;
        const beforeUnload = (event: BeforeUnloadEvent) => { event.preventDefault(); event.returnValue = ""; };
        window.addEventListener("beforeunload", beforeUnload);
        return () => window.removeEventListener("beforeunload", beforeUnload);
    }, [dirty]);

    function returnToFollowups() {
        const search = routeState?.editReturnSearch || "?tab=followups";
        return `/renewal/${memberCourseId ?? planParam}${search}`;
    }
    async function leave() {
        if (saving || inFlight.current) return;
        if (dirty && !await confirmDialog("尚有未儲存的內容，確定離開？")) return;
        setHasUnsavedChanges(false);
        navigate(returnToFollowups(), { state: routeState, preventScrollReset: true });
    }
    function update<K extends keyof FormValues>(key: K, value: FormValues[K]) {
        setValues((current) => ({ ...current, [key]: value })); setDirty(true);
        setErrors((current) => ({ ...current, [key]: undefined, form: undefined }));
    }
    async function submit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (inFlight.current || saving || memberCourseId === null || followupId === null || !record) return;
        const nextErrors: Errors = {};
        const localDateTime = `${values.createdDate}T${values.contactHour}:${values.contactMinute}`;
        if (!values.createdDate || !values.contactHour || !values.contactMinute) nextErrors.createdDate = "請填寫本次聯繫時間";
        else if (!validDateTime(localDateTime)) nextErrors.createdDate = "請輸入有效的日期與時間";
        const unchangedTime = record.createdDate !== null && localDateTime === `${record.createdDate.slice(0, 16)}`;
        if (!nextErrors.createdDate && localDateTime > taipeiNow()) nextErrors.createdDate = "本次聯繫時間不可晚於現在";
        if (!methods.some(([code]) => code === values.contactMethod)) nextErrors.contactMethod = "請選擇有效的聯絡方式";
        if (!statuses.some(([code]) => code === values.status)) nextErrors.status = "請選擇有效的跟進結果";
        if (stripWhitespace(values.note).length > 500) nextErrors.note = "聯繫內容不可超過 500 個字";
        if (Object.keys(nextErrors).length) { setErrors(nextErrors); return; }
        const contactTimeChanged = !unchangedTime;
        const body = {
            createdDate: contactTimeChanged ? `${localDateTime}:00` : record.createdDate!,
            contactTimeChanged,
            contactMethod: values.contactMethod,
            status: values.status,
            note: stripWhitespace(values.note) || null,
        };
        inFlight.current = true; setSaving(true); setErrors({});
        try {
            await updateRenewalFollowup(memberCourseId, followupId, body);
            setDirty(false); setHasUnsavedChanges(false);
            navigate(`/renewal/${memberCourseId}?tab=followups`, { replace: true, state: { ...routeState, followupUpdated: true } });
        } catch (error) {
            setErrors({ form: apiErrorText(error) });
        } finally { inFlight.current = false; setSaving(false); }
    }

    const maxDate = taipeiNow().slice(0, 10);
    const methodOptions = values.contactMethod && !methods.some(([code]) => code === values.contactMethod) ? [[values.contactMethod, `未知方式（${values.contactMethod}）`], ...methods] : methods;
    const statusOptions = values.status && !statuses.some(([code]) => code === values.status) ? [[values.status, `未知狀態（${values.status}）`], ...statuses] : statuses;
    return <main className="renewal-create-page renewal-followup-edit-page renewal-content-page"><div className="renewal-create-inner renewal-followup-edit-inner renewal-content-container">
        <header className="renewal-create-topbar"><div><p className="renewal-create-eyebrow">POWER GYM／教練工作台</p><h1 className="renewal-page-title">編輯跟進紀錄</h1></div></header>
        <button type="button" className="renewal-create-back" onClick={leave} disabled={saving}>← 返回關懷紀錄</button>
        <p className="renewal-create-subtitle">更新本次聯繫內容；會員、方案與教練資訊僅供查看。</p>
        {loading && <div className="renewal-create-state" role="status">跟進資料載入中…</div>}
        {!loading && loadError !== null && <section className="renewal-create-state renewal-create-error" role="alert"><h2>{loadError instanceof RenewalApiError && loadError.status === 404 ? "找不到此跟進紀錄" : loadError instanceof RenewalApiError && loadError.status === 403 ? "無權編輯此跟進紀錄" : "跟進資料載入失敗"}</h2><p>{apiErrorText(loadError)}</p><button type="button" onClick={() => setAttempt((n) => n + 1)}>重試</button><button type="button" className="secondary" onClick={leave}>返回關懷紀錄</button></section>}
        {!loading && !loadError && plan && record && <>
            <section className="renewal-create-summary" aria-label="跟進紀錄方案資訊">
                {plan.member.avatarUrl ? <img src={plan.member.avatarUrl} alt="" /> : <span className="renewal-create-avatar" aria-hidden="true">{plan.member.name?.slice(0, 1) || "?"}</span>}
                <div><small>會員</small><strong>{plan.member.name || "—"}</strong></div><i aria-hidden="true" />
                <div><small>課程</small><strong>{plan.course.courseName || "—"}</strong></div><i aria-hidden="true" />
                <div><small>方案編號</small><strong>方案 #{plan.memberCourseId}</strong></div><i aria-hidden="true" />
                <div><small>教練</small><strong>{record.coachName || "—"}</strong></div>
            </section>
            <form className="renewal-create-form" onSubmit={submit} noValidate>
                <div className="renewal-create-form-heading"><div><h2 className="renewal-section-heading">聯繫資訊</h2><p>＊為必填</p></div></div>
                {errors.form && <div className="renewal-create-form-error" role="alert">{errors.form}</div>}
                <fieldset className="renewal-create-time-field" disabled={saving}><legend>聯繫日期與時間＊</legend>
                    <div className="renewal-create-date-time-controls">
                        <label className="renewal-create-field"><span>聯繫日期</span><input type="date" min="1753-01-01" max={maxDate} value={values.createdDate} onChange={(e) => update("createdDate", e.target.value)} aria-invalid={Boolean(errors.createdDate)} /></label>
                        <div className="renewal-create-time-selects"><label className="renewal-create-field"><span>聯繫時間（24 小時制）</span><select value={values.contactHour} onChange={(e) => update("contactHour", e.target.value)} aria-label="聯繫時間小時"><option value="">時</option>{Array.from({ length: 24 }, (_, h) => String(h).padStart(2, "0")).map((h) => <option key={h}>{h}</option>)}</select></label><span className="renewal-create-time-colon" aria-hidden="true">:</span><label className="renewal-create-field"><span>分鐘</span><select value={values.contactMinute} onChange={(e) => update("contactMinute", e.target.value)} aria-label="聯繫時間分鐘"><option value="">分</option>{Array.from({ length: 60 }, (_, m) => String(m).padStart(2, "0")).map((m) => <option key={m}>{m}</option>)}</select></label></div>
                    </div>{errors.createdDate && <small className="renewal-create-field-error">{errors.createdDate}</small>}
                </fieldset>
                <div className="renewal-create-two-columns">
                    <label className="renewal-create-field"><span>聯絡方式＊</span><select value={values.contactMethod} disabled={saving} onChange={(e) => update("contactMethod", e.target.value)}><option value="">請選擇</option>{methodOptions.map(([code, label]) => <option key={code} value={code}>{label}</option>)}</select>{errors.contactMethod && <small className="renewal-create-field-error">{errors.contactMethod}</small>}</label>
                    <label className="renewal-create-field"><span>跟進結果＊</span><select value={values.status} disabled={saving} onChange={(e) => update("status", e.target.value)}><option value="">請選擇</option>{statusOptions.map(([code, label]) => <option key={code} value={code}>{label}</option>)}</select>{errors.status && <small className="renewal-create-field-error">{errors.status}</small>}</label>
                </div>
                <label className="renewal-create-field renewal-create-note-field"><span>聯繫內容（選填）</span><textarea rows={5} value={values.note} disabled={saving} placeholder="請輸入本次聯繫內容…" onChange={(e) => update("note", e.target.value)} aria-invalid={Boolean(errors.note)} /><span className="renewal-create-note-count">{stripWhitespace(values.note).length}／500</span>{errors.note && <small className="renewal-create-field-error">{errors.note}</small>}</label>
                <div className="renewal-create-footer"><div className="renewal-create-guidance"><p>可修改聯繫時間、聯絡方式、跟進結果及備註。</p><p>更新後仍為同一筆跟進紀錄。</p></div><div className="renewal-create-actions"><button type="button" className="renewal-create-cancel" onClick={leave} disabled={saving}>取消</button><button type="submit" className="renewal-create-submit" disabled={saving}>{saving ? "儲存中…" : "儲存修改"}</button><small>儲存後返回關懷紀錄。</small></div></div>
            </form>
        </>}
    </div></main>;
}
