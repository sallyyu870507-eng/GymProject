import { addDays, today } from "../utils/format.js";

export default function DateNav({ date, onChange, info }) {
  return (
    <div className="card row">
      <button className="btn ghost sm" onClick={() => onChange(addDays(date, -1))}>‹ 前一天</button>
      <input type="date" value={date} aria-label="選擇日期"
             onChange={e => e.target.value && onChange(e.target.value)} />
      <button className="btn ghost sm" onClick={() => onChange(addDays(date, 1))}>後一天 ›</button>
      <button className="btn sm" onClick={() => onChange(today())}>今天</button>
      {info && <span className="hint">{info}</span>}
    </div>
  );
}
