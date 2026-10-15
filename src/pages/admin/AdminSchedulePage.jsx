import { useMemo, useState } from "react";
import { gymApi } from "../../api/gymApi.js";
import { useAsync } from "../../hooks/useAsync.js";
import DateNav from "../../components/DateNav.jsx";
import { ErrorState, Loading } from "../../components/State.jsx";
import { hhmm, today } from "../../utils/format.js";

// 對照「管理端流程圖」：coaches 產生欄位、timeSlots 產生列、schedules 依 coachid + starttime 填入格子
const HOURS = Array.from({ length: 11 }, (_, i) => `${String(9 + i).padStart(2, "0")}:00`);   // 09:00 – 19:00

function Cell({ s }) {
  if (!s) return <span className="hint">—</span>;
  switch (s.status) {
    case "booked":    return <div className="slot booked"><b>{s.membername}</b><br />{s.coursename}</div>;
    case "available": return <div className="slot available">＋ 可預約</div>;
    case "closed":    return <div className="slot closed">⛔ 休息</div>;
    case "private":   return <div className="slot private">🔒 私人安排</div>;
    default:          return <span>{s.status}</span>;
  }
}

export default function AdminSchedulePage() {
  const [date, setDate] = useState(today());
  const coaches = useAsync(() => gymApi.adminCoaches(), []);      // 就算當天沒課，教練欄位也要顯示
  const day = useAsync(() => gymApi.adminDay(date), [date]);

  const { map, rows } = useMemo(() => {
    const list = day.data ?? [];
    return {
      map: new Map(list.map(s => [`${s.coachid}|${hhmm(s.starttime)}`, s])),
      rows: [...new Set([...HOURS, ...list.map(s => hhmm(s.starttime))])].sort(),
    };
  }, [day.data]);

  const cs = coaches.data ?? [];

  return (
    <>
      <h1>全館教練排課表</h1>
      <DateNav date={date} onChange={setDate} info={`共 ${cs.length} 位教練 · ${date}`} />

      {coaches.error ? <ErrorState error={coaches.error} /> :
        day.error ? <ErrorState error={day.error} /> :
        coaches.loading || day.loading ? <Loading /> : (
          <div className="card">
            <table className="grid">
              <thead>
                <tr><th>時間</th>{cs.map(c => <th key={c.coachid}>{c.coachname}</th>)}</tr>
              </thead>
              <tbody>
                {rows.map(h => (
                  <tr key={h}>
                    <td>{h}</td>
                    {cs.map(c => <td key={c.coachid}><Cell s={map.get(`${c.coachid}|${h}`)} /></td>)}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

      <div className="card row">
        <span className="slot booked">已預約（會員＋課程）</span><span className="slot available">＋ 可預約</span>
        <span className="slot closed">⛔ 休息、不可排課</span><span className="slot private">🔒 私人安排</span>
      </div>
    </>
  );
}
