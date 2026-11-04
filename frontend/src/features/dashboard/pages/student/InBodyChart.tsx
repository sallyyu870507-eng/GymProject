import { useEffect, useRef, useState } from 'react';

type InBodyRecord = {
  inbodyid: number;
  recorddate: string | null;
  weight: number | null;
  bodyfatpct: number | null;
  musclemass: number | null;
};

type MetricKey = 'weight' | 'bodyfatpct' | 'musclemass';

const metrics: { key: MetricKey; label: string; unit: string; minRange: number }[] = [
  { key: 'weight', label: '體重', unit: 'kg', minRange: 5 },
  { key: 'bodyfatpct', label: '體脂率', unit: '%', minRange: 5 },
  { key: 'musclemass', label: '肌肉量', unit: 'kg', minRange: 4 },
];

function dateLabel(value: string | null) {
  return value ? value.replaceAll('-', '/') : '日期未記錄';
}

function metricLabel(value: number, unit: string) {
  return `${value.toFixed(1)} ${unit}`;
}

function niceStep(rawStep: number) {
  const magnitude = 10 ** Math.floor(Math.log10(rawStep));
  const fraction = rawStep / magnitude;
  const factor = fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 2.5 ? 2.5 : fraction <= 5 ? 5 : 10;
  return factor * magnitude;
}

export default function InBodyChart({ records }: { records: InBodyRecord[] }) {
  const container = useRef<HTMLDivElement>(null);
  const [width, setWidth] = useState(400);
  const [metricKey, setMetricKey] = useState<MetricKey>('weight');
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const metric = metrics.find((item) => item.key === metricKey)!;

  const data = records
    .filter((item) => item.recorddate && Number.isFinite(Date.parse(item.recorddate)))
    .sort((a, b) => a.recorddate!.localeCompare(b.recorddate!) || a.inbodyid - b.inbodyid)
    .slice(-12);
  const points = data.flatMap((record, index) => {
    const value = record[metricKey];
    return value == null || !Number.isFinite(value) ? [] : [{ record, index, value }];
  });

  useEffect(() => {
    const element = container.current;
    if (!element || typeof ResizeObserver === 'undefined') return;
    const observer = new ResizeObserver(([entry]) => {
      setWidth(Math.max(240, Math.floor(entry.contentRect.width)));
    });
    observer.observe(element);
    return () => observer.disconnect();
  }, []);

  useEffect(() => setSelectedId(null), [metricKey]);

  if (data.length === 0 || points.length === 0) {
    return (
      <section className="member-inbody-chart" aria-label="InBody 趨勢圖">
        <MetricTabs selected={metricKey} onSelect={setMetricKey} />
        <div className="member-chart-heading"><strong>{metric.label}趨勢</strong><span>單位：{metric.unit}</span></div>
        <p className="member-inbody-chart-empty">目前沒有{metric.label}量測資料。</p>
      </section>
    );
  }

  const height = 272;
  const left = 70;
  const right = width - 42;
  const top = 28;
  const bottom = height - 60;
  const values = points.map((point) => point.value);
  const dataMin = Math.min(...values);
  const dataMax = Math.max(...values);
  const center = (dataMin + dataMax) / 2;
  const range = Math.max((dataMax - dataMin) * 1.3, metric.minRange);
  const step = niceStep(range / 4);
  const axisMin = Math.floor((center - range / 2) / step) * step;
  const axisMax = Math.ceil((center + range / 2) / step) * step;
  const tickCount = Math.round((axisMax - axisMin) / step);
  const precision = step < 1 ? 1 : 0;
  const ticks = Array.from({ length: tickCount + 1 }, (_, index) => axisMin + index * step);
  const dates = data.map((item) => Date.parse(`${item.recorddate}T00:00:00Z`));
  const firstDate = dates[0];
  const lastDate = dates[dates.length - 1];
  const xForIndex = (index: number) => firstDate === lastDate
    ? (left + right) / 2
    : left + ((dates[index] - firstDate) / (lastDate - firstDate)) * (right - left);
  const yForValue = (value: number) => bottom - ((value - axisMin) / (axisMax - axisMin)) * (bottom - top);

  let lineStarted = false;
  const linePath = data.map((record, index) => {
    const value = record[metricKey];
    if (value == null || !Number.isFinite(value)) {
      lineStarted = false;
      return '';
    }
    const command = lineStarted ? 'L' : 'M';
    lineStarted = true;
    return `${command}${xForIndex(index)},${yForValue(value)}`;
  }).join(' ');

  const labelIndexes = new Set<number>();
  if (data.length === 1) labelIndexes.add(0);
  else {
    labelIndexes.add(0);
    labelIndexes.add(data.length - 1);
    const labelCount = Math.max(2, Math.floor((right - left) / 72));
    for (let i = 0; i < labelCount; i += 1) {
      labelIndexes.add(Math.round(i * (data.length - 1) / (labelCount - 1)));
    }
  }
  const selected = points.find((point) => point.record.inbodyid === selectedId);
  const selectedX = selected ? xForIndex(selected.index) : 0;
  const selectedY = selected ? yForValue(selected.value) : 0;

  return (
    <section className="member-inbody-chart" aria-label="InBody 趨勢圖">
      <MetricTabs selected={metricKey} onSelect={setMetricKey} />
      <div className="member-chart-heading"><strong>{metric.label}趨勢</strong><span>單位：{metric.unit}</span></div>
      <div className="member-inbody-chart-plot" ref={container}>
        <svg viewBox={`0 0 ${width} ${height}`} role="group" aria-label={`${metric.label}趨勢，縱軸單位 ${metric.unit}，${points.length} 筆量測`}>
          <text x={left} y={14} className="member-inbody-axis-unit">{metric.unit}</text>
          {ticks.map((tick) => (
            <g key={tick} className="member-inbody-grid-line">
              <line x1={left} x2={right} y1={yForValue(tick)} y2={yForValue(tick)} />
              <text x={left - 8} y={yForValue(tick) + 4} textAnchor="end">{tick.toFixed(precision)}</text>
            </g>
          ))}
          <path d={linePath} className="member-inbody-line" />
          {points.map(({ record, index, value }) => (
            <g
              key={record.inbodyid}
              className="member-inbody-point"
              tabIndex={0}
              role="button"
              aria-label={`${dateLabel(record.recorddate)}：${metric.label} ${metricLabel(value, metric.unit)}`}
              onClick={() => setSelectedId(record.inbodyid)}
              onFocus={() => setSelectedId(record.inbodyid)}
              onKeyDown={(event) => {
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault();
                  setSelectedId(record.inbodyid);
                }
              }}
            >
              <title>{dateLabel(record.recorddate)}：{metric.label} {metricLabel(value, metric.unit)}</title>
              <circle cx={xForIndex(index)} cy={yForValue(value)} r={5} />
            </g>
          ))}
          {Array.from(labelIndexes).sort((a, b) => a - b).map((index) => (
            <text key={data[index].inbodyid} x={xForIndex(index)} y={height - 20} textAnchor="middle" className="member-inbody-date-label">
              {dateLabel(data[index].recorddate).slice(5)}
            </text>
          ))}
        </svg>
        {selected && (
          <div
            className="member-inbody-tooltip"
            style={{ left: `${Math.max(72, Math.min(width - 72, selectedX))}px`, top: `${Math.max(70, selectedY - 12)}px` }}
            role="status"
          >
            <strong>{dateLabel(selected.record.recorddate)}</strong>
            <span>{metric.label}：{metricLabel(selected.value, metric.unit)}</span>
          </div>
        )}
      </div>
    </section>
  );
}

function MetricTabs({ selected, onSelect }: { selected: MetricKey; onSelect: (key: MetricKey) => void }) {
  return (
    <div className="member-inbody-metric-tabs" role="group" aria-label="InBody 圖表指標">
      {metrics.map((item) => (
        <button key={item.key} type="button" aria-pressed={selected === item.key} className={selected === item.key ? 'is-active' : ''} onClick={() => onSelect(item.key)}>
          {item.label}
        </button>
      ))}
    </div>
  );
}
