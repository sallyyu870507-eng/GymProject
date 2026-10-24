import { useEffect, useLayoutEffect, useRef, useState, type FormEvent } from "react";
import { useLocation, useNavigate, useOutletContext, useParams } from "react-router";
import { createRenewalFollowup, getRenewalOverview, RenewalApiError, type CreateFollowupRequest } from "../../services/renewalService";
import type { RenewalOverviewResponse } from "../../types/Renewal";
import RenewalPlanIdentity from "../../components/renewal/RenewalPlanIdentity";
import "../../components/renewal/RenewalContentContainer.css";
import "./RenewalFollowupCreatePage.css";

type LayoutContext = {
    setHasUnsavedChanges: (value: boolean) => void;
    setNavigationLocked: (value: boolean) => void;
};
type NavigationState = {
    restoreFilters?: unknown;
    returnScrollY?: number;
    fromDetailsSearch?: string;
};
type FormValues = {
    createdDate: string;
    contactHour: string;
    contactMinute: string;
    contactMethod: string;
    status: string;
    note: string;
};
type FieldErrors = Partial<Record<keyof FormValues, string>> & { form?: string };
type PendingSubmission = { key: string; body: CreateFollowupRequest };

const contactMethodOptions = [
    ["PHONE", "電話"], ["MESSAGE", "訊息"], ["IN_PERSON", "當面"], ["OTHER", "其他"],
];
const outcomeOptions = [
    ["NO_RESPONSE", "尚未取得回應"], ["CONSIDERING", "考慮中"], ["AGREED", "同意續約"], ["DECLINED", "無意願"],
];

function taipeiNowValue() {
    return new Intl.DateTimeFormat("sv-SE", {
        timeZone: "Asia/Taipei", year: "numeric", month: "2-digit", day: "2-digit",
        hour: "2-digit", minute: "2-digit", hourCycle: "h23",
    }).format(new Date()).replace(" ", "T");
}

function initialValues(): FormValues {
    const [createdDate, time] = taipeiNowValue().split("T");
    const [contactHour, contactMinute] = time.split(":");
    return { createdDate, contactHour, contactMinute, contactMethod: "PHONE", status: "NO_RESPONSE", note: "" };
}

function stripBackendWhitespace(value: string) {
    // Match Java String.strip()/Character.isWhitespace used by FollowUpCreateService.
    return value.replace(/^[\u0009-\u000D\u001C-\u001F\u0020\u1680\u2000-\u2006\u2008-\u200A\u2028\u2029\u205F\u3000]+|[\u0009-\u000D\u001C-\u001F\u0020\u1680\u2000-\u2006\u2008-\u200A\u2028\u2029\u205F\u3000]+$/gu, "");
}

function createSubmissionId() {
    if (typeof crypto.randomUUID === "function") return crypto.randomUUID();
    const bytes = crypto.getRandomValues(new Uint8Array(16));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    const hex = [...bytes].map((value) => value.toString(16).padStart(2, "0")).join("");
    return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

function isValidLocalDateTime(value: string) {
    const match = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/.exec(value);
    if (!match) return false;
    const [, yearText, monthText, dayText, hourText, minuteText] = match;
    const year = Number(yearText);
    const month = Number(monthText);
    const day = Number(dayText);
    const hour = Number(hourText);
    const minute = Number(minuteText);
    const date = new Date(Date.UTC(year, month - 1, day, hour, minute));
    return year >= 1753 && year <= 9999
        && date.getUTCFullYear() === year
        && date.getUTCMonth() === month - 1
        && date.getUTCDate() === day
        && hour <= 23 && minute <= 59;
}

function validate(values: FormValues): FieldErrors {
    const errors: FieldErrors = {};
    const localDateTime = `${values.createdDate}T${values.contactHour}:${values.contactMinute}`;
    if (!values.createdDate) errors.createdDate = "請填寫本次聯繫時間";
    else if (!isValidLocalDateTime(localDateTime)) errors.createdDate = "請輸入有效的日期與時間";
    else if (localDateTime > taipeiNowValue()) errors.createdDate = "本次聯繫時間不可晚於現在";
    if (!contactMethodOptions.some(([code]) => code === values.contactMethod)) errors.contactMethod = "請選擇聯絡方式";
    if (!outcomeOptions.some(([code]) => code === values.status)) errors.status = "請選擇跟進結果";
    if (stripBackendWhitespace(values.note).length > 500) errors.note = "聯繫內容不可超過 500 個字";
    return errors;
}

function formatRequestError(error: unknown) {
    if (error instanceof RenewalApiError) {
        if (error.status === 401) return error.message || "登入狀態已失效，請重新登入。";
        if (error.status === 403) return error.message || "目前帳號沒有權限新增此方案的跟進紀錄。";
        if (error.status === 404) return error.message || "找不到此購課方案。";
        return error.message || `新增失敗（HTTP ${error.status}），請檢查內容後重試。`;
    }
    return "無法確認伺服器是否已收到提交。";
}

function RenewalFollowupCreatePage() {
    const { memberCourseId: idParam } = useParams();
    const memberCourseId = idParam && /^[1-9]\d*$/.test(idParam) ? Number(idParam) : null;
    const navigate = useNavigate();
    const location = useLocation();
    const routeState = location.state as NavigationState | null;
    const { setHasUnsavedChanges, setNavigationLocked } = useOutletContext<LayoutContext>();
    const [plan, setPlan] = useState<RenewalOverviewResponse | null>(null);
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState<unknown>(null);
    const [loadAttempt, setLoadAttempt] = useState(0);
    const [values, setValues] = useState<FormValues>(initialValues);
    const [errors, setErrors] = useState<FieldErrors>({});
    const [dirty, setDirty] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    const [outcomeUnknown, setOutcomeUnknown] = useState(false);
    const [needsNewSubmission, setNeedsNewSubmission] = useState(false);
    const [processingConflict, setProcessingConflict] = useState(false);
    const [submissionLockMessage, setSubmissionLockMessage] = useState("");
    const submissionInFlight = useRef(false);
    const pendingSubmission = useRef<PendingSubmission | null>(null);
    const createdDateRef = useRef<HTMLInputElement>(null);
    const contactMethodRef = useRef<HTMLSelectElement>(null);
    const statusRef = useRef<HTMLSelectElement>(null);
    const noteRef = useRef<HTMLTextAreaElement>(null);

    useLayoutEffect(() => {
        const pageScroller = document.scrollingElement;
        if (pageScroller) pageScroller.scrollTop = 0;
    }, [location.pathname]);

    useEffect(() => {
        if (memberCourseId === null) {
            setLoading(false);
            setLoadError(new RenewalApiError(404, "找不到此購課方案。"));
            return;
        }
        const controller = new AbortController();
        setPlan(null);
        setLoadError(null);
        setLoading(true);
        setValues(initialValues());
        setErrors({});
        setDirty(false);
        setOutcomeUnknown(false);
        setNeedsNewSubmission(false);
        setProcessingConflict(false);
        setSubmissionLockMessage("");
        pendingSubmission.current = null;
        void getRenewalOverview(memberCourseId, controller.signal)
            .then((result) => { if (!controller.signal.aborted) setPlan(result); })
            .catch((requestError: unknown) => {
                if (!controller.signal.aborted) setLoadError(requestError);
            })
            .finally(() => { if (!controller.signal.aborted) setLoading(false); });
        return () => controller.abort();
    }, [memberCourseId, loadAttempt]);

    useEffect(() => {
        setHasUnsavedChanges(dirty);
        setNavigationLocked(submitting);
        return () => {
            setHasUnsavedChanges(false);
            setNavigationLocked(false);
        };
    }, [dirty, submitting, setHasUnsavedChanges, setNavigationLocked]);

    useEffect(() => {
        if (!dirty) return;
        const warnBeforeUnload = (event: BeforeUnloadEvent) => {
            event.preventDefault();
            event.returnValue = "";
        };
        window.addEventListener("beforeunload", warnBeforeUnload);
        return () => window.removeEventListener("beforeunload", warnBeforeUnload);
    }, [dirty]);

    function returnPath() {
        const sourceSearch = routeState?.fromDetailsSearch;
        return `/renewal/${memberCourseId ?? idParam}${sourceSearch || "?tab=overview"}`;
    }

    function leaveForm() {
        if (submitting || submissionInFlight.current) return;
        if (dirty && !window.confirm("尚有未儲存的內容，確定離開？")) return;
        setHasUnsavedChanges(false);
        navigate(returnPath(), { state: routeState });
    }

    function updateField<K extends keyof FormValues>(field: K, value: FormValues[K]) {
        setValues((current) => ({ ...current, [field]: value }));
        setDirty(true);
        setErrors((current) => ({ ...current, [field]: undefined, form: undefined }));
    }

    function refreshFailedState(error: unknown) {
        const message = formatRequestError(error);
        if (error instanceof RenewalApiError && error.status === 400) {
            setErrors({ form: message });
            return;
        }
        if (error instanceof RenewalApiError && error.status === 409) {
            setSubmissionLockMessage(message);
            if (/仍在處理/.test(message)) {
                setProcessingConflict(true);
            } else {
                setOutcomeUnknown(true);
                setNeedsNewSubmission(true);
            }
            return;
        }
        if (!(error instanceof RenewalApiError) || error.status >= 500) {
            setOutcomeUnknown(true);
            setSubmissionLockMessage("結果尚未確認，請先查詢紀錄；請勿直接再次新增。");
            return;
        }
        setErrors({ form: message });
    }

    async function sendSubmission(submission: PendingSubmission) {
        if (submissionInFlight.current) return;
        submissionInFlight.current = true;
        setSubmitting(true);
        setErrors({});
        setProcessingConflict(false);
        try {
            await createRenewalFollowup(memberCourseId!, submission.body, submission.key);
            pendingSubmission.current = null;
            setValues(initialValues());
            setDirty(false);
            setHasUnsavedChanges(false);
            const query = new URLSearchParams({ tab: "followups" });
            navigate(`/renewal/${memberCourseId}?${query.toString()}`, {
                replace: true,
                state: { ...routeState, followupCreated: true },
            });
        } catch (requestError) {
            console.error("新增跟進紀錄失敗：", requestError);
            refreshFailedState(requestError);
        } finally {
            submissionInFlight.current = false;
            setSubmitting(false);
        }
    }

    function submit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault();
        if (submissionInFlight.current || outcomeUnknown || needsNewSubmission || processingConflict) return;
        if (!plan?.actions.canAddFollowup || memberCourseId === null) return;

        const validationErrors = validate(values);
        setErrors(validationErrors);
        const firstInvalid = (Object.keys(validationErrors) as Array<keyof FormValues>)[0];
        if (firstInvalid) {
            ({ createdDate: createdDateRef, contactHour: createdDateRef, contactMinute: createdDateRef, contactMethod: contactMethodRef, status: statusRef, note: noteRef }[firstInvalid])?.current?.focus();
            return;
        }

        const normalizedNote = stripBackendWhitespace(values.note);
        const body: CreateFollowupRequest = {
            createdDate: `${values.createdDate}T${values.contactHour}:${values.contactMinute}:00`,
            contactMethod: values.contactMethod,
            status: values.status,
            note: normalizedNote || null,
        };
        const submission = { key: createSubmissionId(), body };
        pendingSubmission.current = submission;
        void sendSubmission(submission);
    }

    function retrySameSubmission() {
        if (pendingSubmission.current) void sendSubmission(pendingSubmission.current);
    }

    function confirmNewSubmission() {
        pendingSubmission.current = null;
        setOutcomeUnknown(false);
        setNeedsNewSubmission(false);
        setProcessingConflict(false);
        setSubmissionLockMessage("");
        setErrors({});
    }

    const formLocked = submitting || outcomeUnknown || needsNewSubmission || processingConflict;
    const requestFailedUnknown = outcomeUnknown || needsNewSubmission;
    const taipeiMax = taipeiNowValue();

    return (
        <main className="renewal-create-page renewal-followup-create-page renewal-content-page">
            <div className="renewal-create-inner renewal-followup-create-inner renewal-content-container">
                <header className="renewal-create-topbar">
                    <div><p className="renewal-create-eyebrow">POWER GYM／教練工作台</p><h1 className="renewal-page-title">新增跟進紀錄</h1></div>
                </header>

                <RenewalPlanIdentity
                    plan={plan}
                    backLabel="返回方案詳情"
                    onBack={leaveForm}
                    backDisabled={submitting}
                />
                {plan && <section className="renewal-create-plan-info" aria-label="目前方案堂數資訊">
                    <span>目前方案</span>
                    <strong>剩餘 {plan.course.remainingSessions} 堂</strong>
                    <i aria-hidden="true" />
                    <strong>總堂數 {plan.course.totalSessions} 堂</strong>
                </section>}
                <p className="renewal-create-subtitle">記錄與學員的聯繫內容，持續追蹤並維持良好互動。</p>

                {loading && <div className="renewal-create-state" role="status">方案資料載入中…</div>}
                {!loading && loadError !== null && <section className="renewal-create-state renewal-create-error" role="alert">
                    <h2>{loadError instanceof RenewalApiError && loadError.status === 404 ? "找不到此購課方案" : loadError instanceof RenewalApiError && loadError.status === 403 ? "無權新增跟進紀錄" : "方案資料載入失敗"}</h2>
                    <p>{formatRequestError(loadError)}</p>
                    <button type="button" onClick={() => setLoadAttempt((value) => value + 1)}>重試</button>
                    <button type="button" className="secondary" onClick={leaveForm}>返回方案詳情</button>
                </section>}

                {!loading && !loadError && plan && <>
                    {!plan.actions.canAddFollowup ? <section className="renewal-create-state" role="status">
                        <h2>目前無法新增跟進</h2><p>此方案目前不可新增跟進紀錄。</p>
                        <button type="button" onClick={leaveForm}>返回方案詳情</button>
                    </section> : <form className="renewal-create-form" onSubmit={submit} noValidate>
                        <div className="renewal-create-form-heading">
                            <div><h2 className="renewal-section-heading">聯繫資訊</h2><p>＊為必填</p></div>
                        </div>

                        {errors.form && <div className="renewal-create-form-error" role="alert">{errors.form}</div>}
                        {submissionLockMessage && <div className="renewal-create-uncertain" role="alert">
                            <strong>{requestFailedUnknown ? "結果尚未確認，請先查詢紀錄" : "提交仍在處理"}</strong>
                            <p>{submissionLockMessage}</p>
                            <a href={`/renewal/${memberCourseId}?tab=followups`} target="_blank" rel="noreferrer">在新分頁查詢關懷紀錄</a>
                            {processingConflict && <button type="button" onClick={retrySameSubmission} disabled={submitting}>使用相同提交編號與內容重試</button>}
                            {requestFailedUnknown && <button type="button" onClick={confirmNewSubmission}>已查詢並確認前次結果，開始新的提交</button>}
                        </div>}

                        <fieldset className="renewal-create-time-field" disabled={formLocked}>
                            <legend>聯繫日期與時間＊</legend>
                            <div className="renewal-create-date-time-controls">
                                <label className="renewal-create-field">
                                    <span>聯繫日期</span>
                                    <input
                                        ref={createdDateRef} type="date" min="1753-01-01" max={taipeiMax.slice(0, 10)}
                                        value={values.createdDate}
                                        onChange={(event) => updateField("createdDate", event.target.value)}
                                        aria-invalid={Boolean(errors.createdDate)} aria-describedby={errors.createdDate ? "create-date-error" : undefined}
                                    />
                                </label>
                                <div className="renewal-create-time-selects">
                                    <label className="renewal-create-field">
                                        <span>聯繫時間（24 小時制）</span>
                                        <select value={values.contactHour} onChange={(event) => updateField("contactHour", event.target.value)} aria-label="聯繫時間小時">
                                            {Array.from({ length: 24 }, (_, hour) => String(hour).padStart(2, "0")).map((hour) => <option key={hour} value={hour}>{hour}</option>)}
                                        </select>
                                    </label>
                                    <span className="renewal-create-time-colon" aria-hidden="true">:</span>
                                    <label className="renewal-create-field">
                                        <span>分鐘</span>
                                        <select value={values.contactMinute} onChange={(event) => updateField("contactMinute", event.target.value)} aria-label="聯繫時間分鐘">
                                            {Array.from({ length: 60 }, (_, minute) => String(minute).padStart(2, "0")).map((minute) => <option key={minute} value={minute}>{minute}</option>)}
                                        </select>
                                    </label>
                                </div>
                            </div>
                            {errors.createdDate && <small id="create-date-error" className="renewal-create-field-error">{errors.createdDate}</small>}
                        </fieldset>

                        <div className="renewal-create-two-columns">
                            <label className="renewal-create-field">
                                <span>聯絡方式＊</span>
                                <select ref={contactMethodRef} value={values.contactMethod} disabled={formLocked} onChange={(event) => updateField("contactMethod", event.target.value)} aria-invalid={Boolean(errors.contactMethod)}>
                                    {contactMethodOptions.map(([code, label]) => <option key={code} value={code}>{label}</option>)}
                                </select>
                                {errors.contactMethod && <small className="renewal-create-field-error">{errors.contactMethod}</small>}
                            </label>
                            <label className="renewal-create-field">
                                <span>跟進結果＊</span>
                                <select ref={statusRef} value={values.status} disabled={formLocked} onChange={(event) => updateField("status", event.target.value)} aria-invalid={Boolean(errors.status)}>
                                    {outcomeOptions.map(([code, label]) => <option key={code} value={code}>{label}</option>)}
                                </select>
                                {errors.status && <small className="renewal-create-field-error">{errors.status}</small>}
                            </label>
                        </div>
                        {values.status === "NO_RESPONSE" && <p className="renewal-create-status-hint">已嘗試聯絡，尚未取得會員回應。</p>}

                        <label className="renewal-create-field renewal-create-note-field">
                            <span>聯繫內容（選填）</span>
                            <textarea ref={noteRef} rows={5} value={values.note} disabled={formLocked} placeholder="請輸入本次聯繫內容…" onChange={(event) => updateField("note", event.target.value)} aria-invalid={Boolean(errors.note)} />
                            <span className="renewal-create-note-count">{stripBackendWhitespace(values.note).length}／500</span>
                            {errors.note && <small className="renewal-create-field-error">{errors.note}</small>}
                        </label>

                        <div className="renewal-create-footer">
                            <div className="renewal-create-guidance"><p>跟進結果：尚未取得回應、考慮中、同意續約、無意願。</p><p>未聯繫由系統依「無跟進紀錄」判定，不提供選取。</p></div>
                            <div className="renewal-create-actions">
                                <button type="button" className="renewal-create-cancel" onClick={leaveForm} disabled={submitting}>取消</button>
                                <button type="submit" className="renewal-create-submit" disabled={formLocked || loading}>
                                    {submitting ? "儲存中…" : "儲存跟進紀錄"}
                                </button>
                                <small>儲存後返回關懷紀錄。</small>
                            </div>
                        </div>
                    </form>}
                </>}
            </div>
        </main>
    );
}

export default RenewalFollowupCreatePage;
