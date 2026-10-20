import type { DayScheduleItem, SlotStatus } from '../api/types';
import { fmtTime } from '../utils/format';

const LABEL: Record<SlotStatus, string> = {
  booked: '已預約',
  available: '可預約',
  private: '私人安排',
  closed: '不開放',
};

export function ScheduleLegend() {
  return (
    <div className="legend">
      {(Object.keys(LABEL) as SlotStatus[]).map((s) => (
        <span key={s}>
          <i className={`swatch st-${s}`} />
          {LABEL[s]}
        </span>
      ))}
    </div>
  );
}

/**
 * 全館教練排課表：教練為欄、時間為列。
 * 照規格書 6.2 的組法，用 coachid + starttime 把資料放進格子。
 */
export function ScheduleGrid({ rows, highlightCoachId }: { rows: DayScheduleItem[]; highlightCoachId?: number }) {
  const coaches = Array.from(new Map(rows.map((r) => [r.coachid, r.coachname])).entries()).sort(
    (a, b) => a[0] - b[0],
  );
  const times = Array.from(new Set(rows.map((r) => r.starttime))).sort();
  const cell = new Map(rows.map((r) => [`${r.coachid}|${r.starttime}`, r]));

  if (!rows.length) return <p className="muted">這天沒有排課資料</p>;

  return (
    <div className="sched-scroll">
      <div className="sched-grid" style={{ gridTemplateColumns: `3.5rem repeat(${coaches.length}, minmax(112px, 1fr))` }}>
        <div />
        {coaches.map(([id, name]) => (
          <div key={id} className={`sched-head ${id === highlightCoachId ? 'is-me' : ''}`}>
            {name}
            {id === highlightCoachId && '（你）'}
          </div>
        ))}
        {times.map((t) => (
          <Row key={t} time={t} coaches={coaches} cell={cell} highlightCoachId={highlightCoachId} />
        ))}
      </div>
    </div>
  );
}

function Row({
  time,
  coaches,
  cell,
  highlightCoachId,
}: {
  time: string;
  coaches: [number, string][];
  cell: Map<string, DayScheduleItem>;
  highlightCoachId?: number;
}) {
  return (
    <>
      <div className="sched-time">{fmtTime(time)}</div>
      {coaches.map(([id]) => {
        const r = cell.get(`${id}|${time}`);
        const status = r?.status ?? 'closed';
        return (
          <div key={id} className={`sched-cell st-${status} ${id === highlightCoachId ? 'is-me' : ''}`}>
            {status === 'booked' ? (
              <>
                <span className="cell-main">{r?.membername}</span>
                <span className="cell-sub">{r?.coursename}</span>
              </>
            ) : (
              <span className="cell-sub">{LABEL[status]}</span>
            )}
          </div>
        );
      })}
    </>
  );
}
