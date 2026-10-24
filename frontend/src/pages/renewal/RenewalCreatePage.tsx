import { useEffect, useLayoutEffect, useRef, useState, type FormEvent } from "react";
import { useLocation, useNavigate, useOutletContext, useParams } from "react-router";
import { createRenewal, getRenewalOptions, RenewalApiError } from "../../services/renewalService";
import type { RenewalCreateRequest, RenewalOptionsResponse } from "../../types/Renewal";
import "../../components/renewal/RenewalContentContainer.css";
import "./RenewalFollowupCreatePage.css";
import "./RenewalCreatePage.css";

type LayoutContext = { setHasUnsavedChanges: (value: boolean) => void; setNavigationLocked: (value: boolean) => void };
type RouteState = { restoreFilters?: unknown; returnScrollY?: number; fromDetailsSearch?: string; [key: string]: unknown };
type Values = { courseId: string; addedSessions: string; amount: string; paymentMethod: string; purchaseDate: string; note: string };
type Errors = Partial<Record<keyof Values, string>> & { form?: string };
type PendingSubmission = { key: string; body: RenewalCreateRequest };
const initialValues: Values = { courseId: "", addedSessions: "", amount: "", paymentMethod: "", purchaseDate: "", note: "" };
const intMax = 2147483647;
const stripWhitespace = (value: string) => value.replace(/^[\u0009-\u000D\u001C-\u001F\u0020\u1680\u2000-\u2006\u2008-\u200A\u2028\u2029\u205F\u3000]+|[\u0009-\u000D\u001C-\u001F\u0020\u1680\u2000-\u2006\u2008-\u200A\u2028\u2029\u205F\u3000]+$/gu, "");

function uuid() {
    if (typeof crypto.randomUUID === "function") return crypto.randomUUID();
    const bytes = crypto.getRandomValues(new Uint8Array(16));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; bytes[8] = (bytes[8] & 0x3f) | 0x80;
    const hex = [...bytes].map((byte) => byte.toString(16).padStart(2, "0")).join("");
    return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
function validDate(value: string) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
    const [year, month, day] = value.split("-").map(Number);
    const check = new Date(Date.UTC(year, month - 1, day));
    return year >= 1 && year <= 9999 && check.getUTCFullYear() === year && check.getUTCMonth() === month - 1 && check.getUTCDate() === day;
}
function errorText(error: unknown) {
    if (!(error instanceof RenewalApiError)) return "連線失敗，無法確認續約是否完成。請先查詢原方案的續約關聯；表單內容與提交編號已保留。";
    if (error.status === 400) return error.message || "欄位內容不符合規定，請檢查後再試。";
    if (error.status === 401) return error.message || "登入狀態已失效，請重新登入。";
    if (error.status === 403) return error.message || "目前帳號沒有權限辦理此方案的續約。";
    if (error.status === 404) return error.message || "找不到此購課方案。";
    if (error.status === 409) return error.message || "續約狀態已變更或提交結果尚未確認，請先查詢原方案的續約關聯。";
    if (error.status >= 500) return "伺服器未能確認續約結果。請先查詢原方案的續約關聯；表單內容與提交編號已保留。";
    return error.message || `辦理續約失敗（HTTP ${error.status}）。`;
}
function isOutcomeUnknown(error: unknown) {
    return !(error instanceof RenewalApiError) || error.status === 409 || error.status >= 500;
}

export default function RenewalCreatePage() {
    const { memberCourseId: idParam } = useParams();
    const memberCourseId = idParam && /^[1-9]\d*$/.test(idParam) ? Number(idParam) : null;
    const navigate = useNavigate(); const location = useLocation();
    const routeState = location.state as RouteState | null;
    const { setHasUnsavedChanges, setNavigationLocked } = useOutletContext<LayoutContext>();
    const [options, setOptions] = useState<RenewalOptionsResponse | null>(null);
    const [loading, setLoading] = useState(true); const [loadError, setLoadError] = useState<unknown>(null); const [attempt, setAttempt] = useState(0);
    const [values, setValues] = useState<Values>(initialValues); const [errors, setErrors] = useState<Errors>({});
    const [dirty, setDirty] = useState(false); const [submitting, setSubmitting] = useState(false);
    const [outcomeUnknown, setOutcomeUnknown] = useState(false); const [unknownMessage, setUnknownMessage] = useState("");
    const [resolvedUnknown, setResolvedUnknown] = useState(false);
    const inFlight = useRef(false); const pending = useRef<PendingSubmission | null>(null);
    const refs = {
        courseId: useRef<HTMLSelectElement>(null), addedSessions: useRef<HTMLInputElement>(null), amount: useRef<HTMLInputElement>(null),
        paymentMethod: useRef<HTMLSelectElement>(null), purchaseDate: useRef<HTMLInputElement>(null), note: useRef<HTMLTextAreaElement>(null),
    };

    useLayoutEffect(() => { if (document.scrollingElement) document.scrollingElement.scrollTop = 0; }, [location.pathname]);
    useEffect(() => {
        const controller = new AbortController(); setLoading(true); setLoadError(null); setOptions(null); setValues(initialValues); setErrors({}); setDirty(false);
        if (memberCourseId === null) { setLoadError(new RenewalApiError(404, "找不到此購課方案。")); setLoading(false); return () => controller.abort(); }
        void getRenewalOptions(memberCourseId, controller.signal).then((result) => {
            if (controller.signal.aborted) return;
            setOptions(result);
            setValues({ ...initialValues, courseId: result.defaultCourseId === null ? "" : String(result.defaultCourseId), purchaseDate: result.defaultPurchaseDate });
        }).catch((error: unknown) => { if (!controller.signal.aborted) setLoadError(error); }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
        return () => controller.abort();
    }, [memberCourseId, attempt]);
    useEffect(() => {
        setHasUnsavedChanges(dirty); setNavigationLocked(submitting);
        return () => { setHasUnsavedChanges(false); setNavigationLocked(false); };
    }, [dirty, submitting, setHasUnsavedChanges, setNavigationLocked]);
    useEffect(() => {
        if (!dirty) return;
        const beforeUnload = (event: BeforeUnloadEvent) => { event.preventDefault(); event.returnValue = ""; };
        window.addEventListener("beforeunload", beforeUnload); return () => window.removeEventListener("beforeunload", beforeUnload);
    }, [dirty]);

    function returnPath() { return `/renewal/${memberCourseId ?? idParam}${routeState?.fromDetailsSearch || "?tab=overview"}`; }
    function leave() {
        if (submitting || inFlight.current) return;
        if (dirty && !window.confirm("尚有未儲存的內容，確定離開？")) return;
        setHasUnsavedChanges(false); navigate(returnPath(), { state: routeState });
    }
    function update<K extends keyof Values>(key: K, value: Values[K]) {
        if (outcomeUnknown) return;
        setValues((current) => ({ ...current, [key]: value })); setDirty(true);
        setErrors((current) => ({ ...current, [key]: undefined, form: undefined }));
    }
    function validate(): Errors {
        const result: Errors = {};
        const courseId = Number(values.courseId);
        if (!options?.courses.some((course) => course.courseId === courseId)) result.courseId = "請選擇目前可辦理的課程";
        if (!/^[0-9]+$/.test(values.addedSessions) || Number(values.addedSessions) < 1 || Number(values.addedSessions) > intMax) result.addedSessions = "購買堂數須為 1 至 2,147,483,647 的整數";
        if (!/^[0-9]+$/.test(values.amount) || Number(values.amount) < 0 || Number(values.amount) > intMax) result.amount = "購課金額須為 0 至 2,147,483,647 的整數";
        if (!options?.paymentMethods.some((method) => method.value === values.paymentMethod)) result.paymentMethod = "請選擇付款方式";
        if (!values.purchaseDate || !validDate(values.purchaseDate)) result.purchaseDate = "請選擇有效的購買日期";
        else if (values.purchaseDate < options!.minPurchaseDate) result.purchaseDate = "購買日期不可早於原方案購買日";
        else if (values.purchaseDate > options!.maxPurchaseDate) result.purchaseDate = "購買日期不可晚於今天";
        if (stripWhitespace(values.note).length > 500) result.note = "備註不可超過 500 個 UTF-16 單位";
        return result;
    }
    async function send(submission: PendingSubmission) {
        if (inFlight.current || memberCourseId === null) return;
        inFlight.current = true; setSubmitting(true); setErrors({});
        try {
            const result = await createRenewal(memberCourseId, submission.body, submission.key);
            pending.current = null; setDirty(false); setHasUnsavedChanges(false);
            const successState = {
                ...routeState,
                renewalCreated: true,
                renewalResult: { newMemberCourseId: result.newMemberCourseId, courseName: result.courseName, addedSessions: result.addedSessions, purchaseDate: result.purchaseDate },
            };
            navigate(`/renewal/${memberCourseId}?tab=overview`, { replace: true, state: successState });
        } catch (error) {
            const message = errorText(error); setErrors({ form: message });
            if (isOutcomeUnknown(error)) {
                setOutcomeUnknown(true); setUnknownMessage(message);
            } else {
                pending.current = null;
            }
        } finally { inFlight.current = false; setSubmitting(false); }
    }
    function submit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (inFlight.current || submitting || outcomeUnknown || !options?.canSubmit || memberCourseId === null) return;
        const validation = validate(); setErrors(validation);
        const firstInvalid = (Object.keys(validation) as Array<keyof Values>)[0];
        if (firstInvalid) { refs[firstInvalid]?.current?.focus(); return; }
        const body: RenewalCreateRequest = {
            courseId: Number(values.courseId), addedSessions: Number(values.addedSessions), amount: Number(values.amount),
            paymentMethod: values.paymentMethod, purchaseDate: values.purchaseDate, note: stripWhitespace(values.note) || null,
        };
        const submission: PendingSubmission = { key: pending.current?.key ?? uuid(), body };
        pending.current = submission;
        void send(submission);
    }
    function confirmResolved() {
        if (!window.confirm("請先確認原方案續約關聯。若已確認前次結果，重新提交將視為一筆新的續約操作。要解除目前提交鎖定嗎？")) return;
        pending.current = null; setOutcomeUnknown(false); setResolvedUnknown(true); setUnknownMessage(""); setErrors({});
    }

    const formLocked = submitting || outcomeUnknown || resolvedUnknown || !options?.canSubmit;
    return <main className="renewal-create-page renewal-renew-create-page renewal-content-page"><div className="renewal-create-inner renewal-new-inner renewal-content-container">
        <header className="renewal-create-topbar"><div><p className="renewal-create-eyebrow">POWER GYM／教練工作台</p><h1 className="renewal-page-title">辦理續約</h1><p className="renewal-create-subtitle">為學員建立新的購課方案，原方案紀錄與剩餘堂數保留。</p></div></header>
        <button type="button" className="renewal-create-back" onClick={leave} disabled={submitting}>← 返回方案詳情</button>
        {loading && <div className="renewal-create-state" role="status">續約資料載入中…</div>}
        {!loading && loadError !== null && <section className="renewal-create-state renewal-create-error" role="alert"><h2>{loadError instanceof RenewalApiError && loadError.status === 403 ? "無權辦理此方案續約" : loadError instanceof RenewalApiError && loadError.status === 404 ? "找不到此購課方案" : "續約資料載入失敗"}</h2><p>{errorText(loadError)}</p><button type="button" onClick={() => setAttempt((value) => value + 1)}>重試</button><button type="button" className="secondary" onClick={leave}>返回方案詳情</button></section>}
        {!loading && !loadError && options && <>
            {options.disabledReason && <div className="renewal-new-disabled-reason" role="status">{options.disabledReason}</div>}
            {outcomeUnknown && <div className="renewal-new-unknown" role="alert"><strong>結果尚未確認，請先查詢紀錄</strong><p>{unknownMessage}</p><a href={`/renewal/${memberCourseId}?tab=overview`} target="_blank" rel="noreferrer">在新分頁查詢原方案續約關聯</a><button type="button" onClick={confirmResolved}>已查詢並確認前次結果，開始新的提交</button><small>確認前不會重新送出，也不會更換原提交編號與內容。</small></div>}
            {resolvedUnknown && <div className="renewal-new-unknown" role="status"><strong>請重新確認本次續約內容</strong><p>下次確認續約會建立新的提交操作及識別碼。</p><button type="button" onClick={() => { setResolvedUnknown(false); setErrors({}); }}>返回表單</button></div>}
            <form className="renewal-new-form" onSubmit={submit} noValidate>
                {errors.form && !outcomeUnknown && <div className="renewal-create-form-error" role="alert">{errors.form}</div>}
                <section className="renewal-new-card"><h2 className="renewal-section-heading">原方案資訊</h2>
                    <Info label="會員" value={options.member.name} /><Info label="原方案編號" value={`#${options.memberCourseId}`} /><Info label="課程" value={options.sourceCourse.courseName} /><Info label="教練" value={options.sourceCourse.coachName} /><Info label="購買日" value={options.sourceCourse.purchaseDate.replaceAll("-", "/")} /><Info label="剩餘／總堂數" value={`${options.sourceCourse.remainingSessions}／${options.sourceCourse.totalSessions} 堂`} />
                </section>
                <section className="renewal-new-card"><h2 className="renewal-section-heading">新購課方案</h2>
                    <label className="renewal-create-field"><span>課程＊</span><select ref={refs.courseId} value={values.courseId} disabled={formLocked} onChange={(event) => update("courseId", event.target.value)} aria-invalid={Boolean(errors.courseId)}><option value="">請選擇課程</option>{options.courses.map((course) => <option key={course.courseId} value={course.courseId}>{course.courseName}</option>)}</select>{errors.courseId && <small className="renewal-create-field-error">{errors.courseId}</small>}<small className="renewal-new-hint">可選目前教練可授課的其他課程。</small></label>
                    <label className="renewal-create-field"><span>教練</span><input value={options.coach.coachName} readOnly /></label>
                    <label className="renewal-create-field"><span>購買堂數＊</span><div className="renewal-new-number"><input ref={refs.addedSessions} type="text" inputMode="numeric" value={values.addedSessions} disabled={formLocked} placeholder="請輸入堂數" onChange={(event) => update("addedSessions", event.target.value)} aria-invalid={Boolean(errors.addedSessions)} /><span>堂</span></div>{errors.addedSessions && <small className="renewal-create-field-error">{errors.addedSessions}</small>}</label>
                    <p className="renewal-new-hint">每次限購一門課程；其他課程請另筆辦理。</p>
                </section>
                <section className="renewal-new-card"><h2 className="renewal-section-heading">續約資料</h2>
                    <label className="renewal-create-field"><span>本次購課金額（NT$）＊</span><input ref={refs.amount} type="text" inputMode="numeric" value={values.amount} disabled={formLocked} placeholder="請輸入金額" onChange={(event) => update("amount", event.target.value)} aria-invalid={Boolean(errors.amount)} />{errors.amount && <small className="renewal-create-field-error">{errors.amount}</small>}<small className="renewal-new-hint">請輸入本次全部購買堂數的成交總額。</small></label>
                    <label className="renewal-create-field"><span>付款方式＊</span><select ref={refs.paymentMethod} value={values.paymentMethod} disabled={formLocked} onChange={(event) => update("paymentMethod", event.target.value)} aria-invalid={Boolean(errors.paymentMethod)}><option value="">請選擇</option>{options.paymentMethods.map((method) => <option key={method.value} value={method.value}>{method.label}</option>)}</select>{errors.paymentMethod && <small className="renewal-create-field-error">{errors.paymentMethod}</small>}</label>
                    <label className="renewal-create-field"><span>購買日期＊</span><input ref={refs.purchaseDate} type="date" min={options.minPurchaseDate} max={options.maxPurchaseDate} value={values.purchaseDate} disabled={formLocked} onChange={(event) => update("purchaseDate", event.target.value)} aria-invalid={Boolean(errors.purchaseDate)} />{errors.purchaseDate && <small className="renewal-create-field-error">{errors.purchaseDate}</small>}<small className="renewal-new-hint">可補登過去購課日期，不可早於原方案購買日或晚於今天。</small></label>
                    <label className="renewal-create-field renewal-create-note-field"><span>備註（選填）</span><textarea ref={refs.note} rows={4} value={values.note} disabled={formLocked} placeholder="請輸入備註" onChange={(event) => update("note", event.target.value)} aria-invalid={Boolean(errors.note)} /><span className="renewal-create-note-count">{values.note.length}／500</span>{errors.note && <small className="renewal-create-field-error">{errors.note}</small>}</label>
                </section>
                <div className="renewal-new-footer"><p>確認後將建立一筆新購課方案，並與原方案建立續約關聯。原方案剩餘堂數保留，不合併至新方案。</p><div><button type="button" onClick={leave} disabled={submitting}>取消</button><button type="submit" disabled={formLocked || loading}>{submitting ? "辦理中…" : "確認續約"}</button></div></div>
            </form>
        </>}
    </div></main>;
}

function Info({ label, value }: { label: string; value: string }) { return <div className="renewal-new-info"><span>{label}</span><strong>{value || "—"}</strong></div>; }
