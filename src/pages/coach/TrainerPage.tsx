import { useState } from 'react';
import { EmptyTable } from '../../components/skeleton';
import { Card, StatTile } from '../../components/ui';
import { fmtMonthDay, todayISO } from '../../utils/format';

/** 教練首頁：日期選擇、當日統計、今日教學課表（課表卡片延伸到視窗底部） */
export default function TrainerPage() {
  const [date, setDate] = useState(todayISO);
  const isToday = date === todayISO();

  return (
    <div className="page page-fill">
      <div className="page-head">
        <label className="date-picker">
          查看日期
          <input
            type="date"
            value={date}
            min="2000-01-01"
            max="2099-12-31"
            onChange={(e) => e.target.value && setDate(e.target.value)}
          />
          {!isToday && (
            <button type="button" className="btn btn-small" onClick={() => setDate(todayISO())}>
              回到今天
            </button>
          )}
        </label>
      </div>

      <div className="tiles">
        <StatTile label={isToday ? '今日課程數' : '當日課程數'} value="—" unit="堂" />
        <StatTile label={isToday ? '今日學員數' : '當日學員數'} value="—" unit="位" hint="不重複學員" />
        <StatTile label="下一堂" value="—" />
      </div>

      <Card title="今日教學課表" subtitle={fmtMonthDay(date)} className="card-fill">
        <EmptyTable fill columns={['時間', '課程名稱', '學生名稱', '狀態', '操作']} emptyText="這天沒有學員預約" />
      </Card>
    </div>
  );
}
