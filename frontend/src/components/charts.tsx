import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import type { InBodyRecord, WeeklyAttendance } from '../api/types';
import { fmtDate, parseDate } from '../utils/format';
import { INBODY_METRICS, metricValue, type InBodyMetric } from '../utils/stats';

/** 圖表配色：深淺色主題都看得清楚的中間色 */
export const CHART_COLORS = ['#4f7cff', '#1f9d6b', '#e8833a', '#a855f7'];

const axisTick = { fontSize: 12 };
const tooltipStyle = {
  contentStyle: {
    background: 'var(--panel)',
    border: '1px solid var(--line)',
    borderRadius: 8,
    fontSize: 13,
  },
  labelStyle: { color: 'var(--muted)' },
};

const monthLabel = (s: string) => `${parseDate(s).getMonth() + 1}月`;
const dayLabel = (s: string) => {
  const d = parseDate(s);
  return `${d.getMonth() + 1}/${d.getDate()}`;
};

interface InBodyChartProps {
  rows: InBodyRecord[];
  metrics: InBodyMetric[];
  height?: number;
}

/** InBody 趨勢折線圖 */
export function InBodyChart({ rows, metrics, height = 240 }: InBodyChartProps) {
  // 依日期排序，並把換算指標（體脂肪重）一起算好給圖表用
  const data = [...rows]
    .sort((a, b) => a.recorddate.localeCompare(b.recorddate))
    .map((r) => ({ ...r, fatmass: metricValue(r, 'fatmass') }));
  return (
    <ResponsiveContainer width="100%" height={height}>
      <LineChart data={data} margin={{ top: 8, right: 12, bottom: 0, left: -12 }}>
        <CartesianGrid vertical={false} />
        <XAxis dataKey="recorddate" tickFormatter={monthLabel} tick={axisTick} tickLine={false} minTickGap={16} />
        <YAxis domain={['auto', 'auto']} tick={axisTick} tickLine={false} axisLine={false} width={44} />
        <Tooltip
          {...tooltipStyle}
          labelFormatter={(v) => fmtDate(String(v))}
          formatter={(value, name) => {
            const meta = INBODY_METRICS[name as InBodyMetric];
            return [`${value} ${meta?.unit ?? ''}`, meta?.label ?? name];
          }}
        />
        {metrics.length > 1 && (
          <Legend formatter={(v) => INBODY_METRICS[v as InBodyMetric]?.label ?? v} iconType="circle" />
        )}
        {metrics.map((m, i) => (
          <Line
            key={m}
            type="linear"
            dataKey={m}
            stroke={CHART_COLORS[m === 'bodyfatpct' ? 2 : i]}
            strokeWidth={2}
            dot={{ r: 3 }}
            activeDot={{ r: 5 }}
          />
        ))}
      </LineChart>
    </ResponsiveContainer>
  );
}

/** 每週到館次數長條圖 */
export function AttendanceChart({ rows, height = 220 }: { rows: WeeklyAttendance[]; height?: number }) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <BarChart data={rows} margin={{ top: 8, right: 4, bottom: 0, left: -24 }}>
        <CartesianGrid vertical={false} />
        <XAxis dataKey="week" tickFormatter={dayLabel} tick={axisTick} tickLine={false} minTickGap={8} />
        <YAxis allowDecimals={false} tick={axisTick} tickLine={false} axisLine={false} />
        <Tooltip
          {...tooltipStyle}
          cursor={{ fill: 'var(--hover)' }}
          labelFormatter={(v) => `${dayLabel(String(v))} 那週`}
          formatter={(value) => [`${value} 次`, '到館']}
        />
        <Bar dataKey="checkins" fill={CHART_COLORS[0]} radius={[4, 4, 0, 0]} maxBarSize={32} />
      </BarChart>
    </ResponsiveContainer>
  );
}
