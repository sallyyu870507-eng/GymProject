/**
 * 不依賴圖表套件的小圖（SVG）：每週到館長條圖、InBody 趨勢折線、剩餘堂數環。
 * 進場動畫寫在 MiniCharts.css，系統開啟「減少動態效果」時會關閉。
 */
import './MiniCharts.css';

/** 每週到館次數：長條一根一根升起，最新一週用品牌橘 */
export function WeeklyBars({ data, height = 150 }: { data: { week: string; checkins: number }[]; height?: number }) {
  const W = 520;
  const H = height;
  const top = 20;
  const bottom = 24;
  const max = Math.max(3, ...data.map((d) => d.checkins));
  const slot = W / data.length;
  const bw = Math.min(26, slot * 0.5);
  const base = H - bottom;
  return (
    <svg className="mc" viewBox={`0 0 ${W} ${H}`} role="img" aria-label="近 12 週每週到館次數">
      {[1, 2, 3].map((g) => (
        <line key={g} x1={0} x2={W} y1={base - ((base - top) * g) / max} y2={base - ((base - top) * g) / max} className="mc-grid" />
      ))}
      <line x1={0} x2={W} y1={base} y2={base} className="mc-axis" />
      {data.map((d, i) => {
        const h = ((base - top) * d.checkins) / max;
        const x = i * slot + (slot - bw) / 2;
        const last = i === data.length - 1;
        const [, m, day] = d.week.split('-').map(Number);
        return (
          <g key={d.week} className="mc-col" style={{ ['--i' as string]: i }}>
            {d.checkins === 0 ? (
              <circle cx={x + bw / 2} cy={base - 3} r={2.5} className="mc-zero" />
            ) : (
              <rect x={x} y={base - h} width={bw} height={h} rx={4} className={last ? 'mc-bar mc-bar-now' : 'mc-bar'} />
            )}
            {d.checkins > 0 && (
              <text x={x + bw / 2} y={base - h - 6} className="mc-val">
                {d.checkins}
              </text>
            )}
            {(i % 3 === 2 || last) && (
              <text x={x + bw / 2} y={H - 6} className={last ? 'mc-tick mc-tick-now' : 'mc-tick'}>
                {last ? '本週' : `${m}/${day}`}
              </text>
            )}
          </g>
        );
      })}
    </svg>
  );
}

/** 體重與肌肉量：兩條線各自縮放，線條依序畫出 */
export function TrendLines({
  data,
  height = 150,
}: {
  data: { recorddate: string; weight: number; musclemass: number }[];
  height?: number;
}) {
  const W = 520;
  const H = height;
  const padX = 24;
  const top = 22;
  const bottom = 24;
  const x = (i: number) => padX + ((W - padX * 2) * i) / Math.max(1, data.length - 1);
  const scale = (vals: number[]) => {
    const lo = Math.min(...vals);
    const hi = Math.max(...vals);
    const span = hi - lo || 1;
    return (v: number) => top + (H - top - bottom) * (1 - (v - lo) / span);
  };
  const yw = scale(data.map((d) => d.weight));
  const ym = scale(data.map((d) => d.musclemass));
  const path = (y: (v: number) => number, key: 'weight' | 'musclemass') =>
    data.map((d, i) => `${i ? 'L' : 'M'}${x(i).toFixed(1)},${y(d[key]).toFixed(1)}`).join(' ');
  const n = data.length - 1;
  return (
    <svg className="mc" viewBox={`0 0 ${W} ${H}`} role="img" aria-label="體重與肌肉量趨勢">
      <line x1={0} x2={W} y1={H - bottom} y2={H - bottom} className="mc-axis" />
      <path d={path(yw, 'weight')} className="mc-line mc-ink" pathLength={1} />
      <path d={path(ym, 'musclemass')} className="mc-line mc-orange" pathLength={1} />
      {data.map((d, i) => {
        const [, m, day] = d.recorddate.split('-').map(Number);
        return (
          <g key={d.recorddate} className="mc-pts" style={{ ['--i' as string]: i }}>
            <circle cx={x(i)} cy={yw(d.weight)} r={i === n ? 4.5 : 3} className="mc-pt mc-ink" />
            <circle cx={x(i)} cy={ym(d.musclemass)} r={i === n ? 4.5 : 3} className="mc-pt mc-orange" />
            <text x={x(i)} y={H - 6} className="mc-tick">
              {m}/{day}
            </text>
          </g>
        );
      })}
    </svg>
  );
}

/** 剩餘堂數環：像一片槓片，剩下的比例用顏色填滿 */
export function SessionRing({ remaining, total, low }: { remaining: number; total: number; low?: boolean }) {
  const r = 34;
  const c = 2 * Math.PI * r;
  const ratio = total ? remaining / total : 0;
  return (
    <svg className="ring" viewBox="0 0 88 88" role="img" aria-label={`剩 ${remaining} 堂，共 ${total} 堂`}>
      <circle cx={44} cy={44} r={r} className="ring-track" />
      <circle
        cx={44}
        cy={44}
        r={r}
        className={low ? 'ring-fill ring-low' : 'ring-fill'}
        strokeDasharray={c}
        style={{ ['--off' as string]: c * (1 - ratio), ['--c' as string]: c }}
        transform="rotate(-90 44 44)"
      />
      <circle cx={44} cy={44} r={9} className="ring-hole" />
    </svg>
  );
}
