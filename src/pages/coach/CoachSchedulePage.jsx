import { useState } from "react";
import { gymApi } from "../../api/gymApi.js";
import { useAsync } from "../../hooks/useAsync.js";
import DataTable from "../../components/DataTable.jsx";
import DateNav from "../../components/DateNav.jsx";
import { ErrorState, Loading } from "../../components/State.jsx";
import { hhmm, today } from "../../utils/format.js";

export default function CoachSchedulePage() {
  const [date, setDate] = useState(today());
  const dash = useAsync(() => gymApi.coachDashboard(date), [date]);
  const list = useAsync(() => gymApi.coachSchedules(date), [date]);

  return (
    <>
      <h1>教學課表</h1>
      <DateNav date={date} onChange={setDate} info={date} />

      {dash.error ? <ErrorState error={dash.error} /> : (
        <div className="stats">
          <div className="card"><div className="hint">課程數</div><div className="stat">{dash.data?.todayCourseCount ?? "–"}</div></div>
          <div className="card"><div className="hint">學員數</div><div className="stat">{dash.data?.todayStudentCount ?? "–"}</div></div>
        </div>
      )}

      <div className="card">
        <h3>已預約的課程</h3>
        {list.loading ? <Loading /> : list.error ? <ErrorState error={list.error} /> : (
          <DataTable
            rows={list.data}
            columns={[
              { label: "時間", render: r => `${hhmm(r.starttime)} – ${hhmm(r.endtime)}` },
              { label: "課程", key: "coursename" },
              { label: "學員", key: "studentname" },
            ]} />
        )}
      </div>
    </>
  );
}
