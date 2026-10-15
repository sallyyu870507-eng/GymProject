import { useState } from "react";
import { Link } from "react-router-dom";
import { gymApi } from "../../api/gymApi.js";
import { useAsync } from "../../hooks/useAsync.js";
import { ErrorState, Loading } from "../../components/State.jsx";
import Badge from "../../components/Badge.jsx";
import { hhmm, isoDate } from "../../utils/format.js";

// 對照「會員端流程圖」：選課程 → 選日期 → 選時段 → 確認預約 → 完成
const STEPS = ["選擇課程", "選擇日期", "選擇時段", "確認預約", "完成"];
const SLOT_LABEL = { available: "可預約", booked: "🚫 已被預約", closed: "🚫 不開放", private: "🔒 私人安排" };

export default function ReservePage() {
  const courses = useAsync(() => gymApi.myCourses(), []);
  const [course, setCourse] = useState(null);
  const [dates, setDates] = useState([]);
  const [date, setDate] = useState(null);
  const [slots, setSlots] = useState([]);
  const [slot, setSlot] = useState(null);
  const [note, setNote] = useState("");
  const [done, setDone] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  // 只顯示剩餘堂數 > 0 的課程
  const list = (courses.data ?? []).filter(c => c.remainingsessions > 0);
  const step = done ? 5 : slot ? 4 : date ? 3 : course ? 2 : 1;

  const run = async fn => {
    setBusy(true); setError(null);
    try { await fn(); } catch (e) { setError(e); } finally { setBusy(false); }
  };

  const pickCourse = c => run(async () => {
    setCourse(c); setDate(null); setSlots([]); setSlot(null);
    setDates((await gymApi.availableDates(c.membercourseid)).map(isoDate));
  });

  const pickDate = d => run(async () => {
    setDate(d); setSlot(null);
    setSlots(await gymApi.slots(course.membercourseid, d));
  });

  const confirm = () => run(async () => {
    try {
      setDone(await gymApi.createBooking({ membercourseid: course.membercourseid, scheduleid: slot.scheduleid, note }));
    } catch (e) {                       // 可能剛好被別人訂走：重抓時段
      setSlot(null);
      try { setSlots(await gymApi.slots(course.membercourseid, date)); } catch { /* 忽略 */ }
      throw e;
    }
  });

  const again = () => {                 // 預約成功後重新取得剩餘堂數，並清空選擇
    setCourse(null); setDates([]); setDate(null); setSlots([]); setSlot(null); setNote(""); setDone(null);
    courses.reload();
  };

  return (
    <>
      <h1>課程預約</h1>
      <div className="stepper">
        {STEPS.map((t, i) => <span key={t} className={i + 1 <= step ? "on" : ""}>{i + 1}. {t}</span>)}
      </div>
      {error && <ErrorState error={error} />}

      {done ? (
        <div className="card">
          <h3>5. 預約成功 ✔</h3>
          <p>
            課程：<b>{done.coursename}</b>（{done.coachname}）<br />
            日期：<b>{isoDate(done.classdate)}</b>　時段：<b>{hhmm(done.starttime)} – {hhmm(done.endtime)}</b><br />
            教室：{done.classroom ?? "—"}　狀態：<Badge cls="ok">✔ {done.bookingstatus}</Badge>
          </p>
          <div className="row">
            <Link className="btn" to="/member/courses">返回我的課程</Link>
            <button className="btn ghost" onClick={again}>再預約一堂</button>
          </div>
        </div>
      ) : (
        <>
          <div className="card">
            <h3>1. 選擇課程</h3>
            <p className="hint">只顯示已購買且剩餘堂數大於 0 的課程</p>
            {courses.loading ? <Loading /> : courses.error ? <ErrorState error={courses.error} /> :
              list.length === 0 ? <div className="state">目前沒有可預約的課程</div> : (
                <div className="options">
                  {list.map(c => {
                    const on = course?.membercourseid === c.membercourseid;
                    return (
                      <button key={c.membercourseid} className={`opt ${on ? "sel" : ""}`} disabled={busy}
                              onClick={() => pickCourse(c)}>
                        <b>{c.coursename}</b>
                        <small>教練：{c.coachname}</small>
                        <small>剩餘堂數：{c.remainingsessions} 堂</small>
                        {on && <small>✔ 已選擇</small>}
                      </button>
                    );
                  })}
                </div>
              )}
          </div>

          {course && (
            <div className="card">
              <h3>2. 選擇日期</h3>
              {dates.length === 0 ? <div className="state">目前沒有可預約的日期</div> : (
                <div className="chips">
                  {dates.map(d => (
                    <button key={d} className={`opt ${date === d ? "sel" : ""}`} disabled={busy} onClick={() => pickDate(d)}>
                      {d}{date === d ? " ✔" : ""}
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}

          {date && (
            <div className="card">
              <h3>3. 選擇時段</h3>
              <p className="hint">已被預約或不開放的時段無法點選</p>
              {slots.length === 0 ? <div className="state">這天沒有時段</div> : (
                <div className="chips">
                  {slots.map(s => {
                    const on = slot?.scheduleid === s.scheduleid;
                    return (
                      <button key={s.scheduleid} className={`opt ${on ? "sel" : ""}`}
                              disabled={busy || s.status !== "available"} onClick={() => setSlot(s)}>
                        {hhmm(s.starttime)} – {hhmm(s.endtime)}
                        <small>{on ? "✔ 已選擇" : SLOT_LABEL[s.status] ?? s.status}</small>
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          )}

          {slot && (
            <div className="card">
              <h3>4. 確認預約</h3>
              <p>
                課程：<b>{course.coursename}</b><br />
                教練：<b>{course.coachname}</b><br />
                日期：<b>{date}</b><br />
                時段：<b>{hhmm(slot.starttime)} – {hhmm(slot.endtime)}</b>
              </p>
              <div className="row">
                <input placeholder="備註（選填）" maxLength={100} value={note} onChange={e => setNote(e.target.value)} />
                <button className="btn" disabled={busy} onClick={confirm}>確認預約</button>
              </div>
            </div>
          )}
        </>
      )}
    </>
  );
}
