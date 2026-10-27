import { useEffect, useRef, useState, type FormEvent, type ReactNode } from 'react';
import { fieldErrorsOf } from '../api/client';

export interface FieldDef<T> {
  name: keyof T & string;
  label: string;
  type?: 'text' | 'password' | 'tel' | 'email' | 'date' | 'select';
  options?: { value: string; label: string }[];
  required?: boolean;
  placeholder?: string;
  hint?: string;
}

interface FormDialogProps<T> {
  title: string;
  fields: FieldDef<T>[];
  /** 表單初始值；傳入 Promise 時先顯示讀取中（例如先 GET 會員舊資料） */
  initial: T | Promise<T>;
  submitLabel?: string;
  onSubmit: (values: T) => Promise<unknown>;
  onClose: () => void;
  footnote?: ReactNode;
}

/**
 * 新增 / 編輯用的對話框。
 * 後端回 400 { errors: { phone: '手機號碼格式錯誤' } } 時，訊息會顯示在對應欄位下面。
 */
export function FormDialog<T extends object>({
  title,
  fields,
  initial,
  submitLabel = '儲存',
  onSubmit,
  onClose,
  footnote,
}: FormDialogProps<T>) {
  const [values, setValues] = useState<T>();
  const [loadError, setLoadError] = useState<string>();
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [formError, setFormError] = useState<string>();
  const [busy, setBusy] = useState(false);
  const firstInput = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    let alive = true;
    Promise.resolve(initial)
      .then((v) => alive && setValues({ ...v }))
      .catch((err: Error) => alive && setLoadError(err.message));
    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (values) firstInput.current?.focus();
  }, [values === undefined]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && !busy && onClose();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [busy, onClose]);

  const set = (name: string, value: string) => {
    setValues((v) => (v ? { ...v, [name]: value } : v));
    setErrors((e) => ({ ...e, [name]: '' }));
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!values) return;
    setBusy(true);
    setErrors({});
    setFormError(undefined);
    try {
      await onSubmit(values);
    } catch (err) {
      const fe = fieldErrorsOf(err);
      setErrors(fe);
      // 有欄位錯誤就顯示在欄位下；不屬於表單欄位的才放在最下面
      const known = fields.some((f) => fe[f.name]);
      if (!known) setFormError((err as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="dialog-backdrop" onMouseDown={(e) => e.target === e.currentTarget && !busy && onClose()}>
      <form className="dialog card" role="dialog" aria-modal="true" aria-label={title} onSubmit={submit} noValidate>
        <header className="card-head">
          <h3>{title}</h3>
          <button type="button" className="btn btn-ghost btn-small" onClick={onClose} disabled={busy} aria-label="關閉">
            ✕
          </button>
        </header>

        {loadError ? (
          <p className="form-error">{loadError}</p>
        ) : !values ? (
          <div className="skeleton" style={{ minHeight: 200 }} />
        ) : (
          <div className="form-grid">
            {fields.map((f, i) => {
              const raw = (values as Record<string, unknown>)[f.name];
              const value = raw === null || raw === undefined ? '' : String(raw);
              const err = errors[f.name];
              return (
                <label key={f.name} className={`field ${err ? 'has-error' : ''}`}>
                  <span>
                    {f.label}
                    {f.required && <em className="req">*</em>}
                  </span>
                  {f.type === 'select' ? (
                    <select className="select" value={value} onChange={(e) => set(f.name, e.target.value)}>
                      {f.options?.map((o) => (
                        <option key={o.value} value={o.value}>
                          {o.label}
                        </option>
                      ))}
                    </select>
                  ) : (
                    <input
                      ref={i === 0 ? firstInput : undefined}
                      type={f.type ?? 'text'}
                      value={value}
                      placeholder={f.placeholder}
                      onChange={(e) => set(f.name, e.target.value)}
                      aria-invalid={Boolean(err)}
                    />
                  )}
                  {err ? <small className="field-error">{err}</small> : f.hint && <small className="muted">{f.hint}</small>}
                </label>
              );
            })}
          </div>
        )}

        {formError && <p className="form-error">{formError}</p>}
        {footnote}

        <div className="actions">
          <button type="button" className="btn" onClick={onClose} disabled={busy}>
            取消
          </button>
          <button type="submit" className="btn btn-primary" disabled={busy || !values}>
            {busy ? '處理中…' : submitLabel}
          </button>
        </div>
      </form>
    </div>
  );
}
