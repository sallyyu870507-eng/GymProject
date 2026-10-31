import { useEffect, useRef, useState } from 'react';


//顯示最近 12 筆紀錄，橫軸按實際日期間隔排列；缺少的數值不會被當成 0。肌肉量使用虛線，
type RecordItem = {
  inbodyid: number;
  recorddate: string | null;
  weight: number | null;
  musclemass: number | null;
};

const series = [
  { key: 'weight', label: '體重', color: 'var(--c1)', dashed: false },
  { key: 'musclemass', label: '肌肉量', color: 'var(--c2)', dashed: true },
] as const;

export default function InBodyChart({
  records,
}: {
  records: RecordItem[];
}) {
  const container = useRef<HTMLDivElement>(null);
  const [width, setWidth] = useState(400);

  const data = records
    .filter((item) =>
      item.recorddate &&
      Number.isFinite(Date.parse(item.recorddate)),
    )
    .sort((a, b) => a.recorddate!.localeCompare(b.recorddate!))
    .slice(-12);

  useEffect(() => {
    if (!container.current) return;

    const observer = new ResizeObserver(([entry]) => {
      setWidth(Math.max(200, Math.floor(entry.contentRect.width)));
    });

    observer.observe(container.current);
    return () => observer.disconnect();
  }, [data.length]);

  const values = data.flatMap((item) =>
    [item.weight, item.musclemass].filter(
      (value): value is number =>
        value != null && Number.isFinite(value),
    ),
  );

  if (!data.length || !values.length) {
    return <p className="muted">目前沒有可繪製的檢測紀錄。</p>;
  }

  const height = 220;
  const left = 44;
  const right = width - 14;
  const top = 24;
  const bottom = height - 40;

  const padding = Math.max(
    1,
    (Math.max(...values) - Math.min(...values)) * 0.1,
  );
  const min = Math.min(...values) - padding;
  const max = Math.max(...values) + padding;

  const dates = data.map((item) => Date.parse(item.recorddate!));
  const first = dates[0];
  const last = dates[dates.length - 1];

  const x = (index: number) =>
    first === last
      ? (left + right) / 2
      : left + ((dates[index] - first) / (last - first)) * (right - left);

  const y = (value: number) =>
    bottom - ((value - min) / (max - min)) * (bottom - top);

  function pathFor(key: 'weight' | 'musclemass') {
    let started = false;

    return data.map((item, index) => {
      const value = item[key];

      if (value == null || !Number.isFinite(value)) {
        started = false;
        return '';
      }

      const command = started ? 'L' : 'M';
      started = true;
      return `${command}${x(index)},${y(value)}`;
    }).join(' ');
  }

  const ticks = [min, (min + max) / 2, max];

  return (
    <div ref={container} style={{ marginTop: 16 }}>
      <div className="legend">
        <span style={{ color: 'var(--c1)' }}>● 體重</span>
        <span style={{ color: 'var(--c2)' }}>┄ 肌肉量</span>
      </div>

      <svg
        width="100%"
        height={height}
        viewBox={`0 0 ${width} ${height}`}
        role="img"
        aria-label={`最近 ${data.length} 筆體重與肌肉量趨勢，單位公斤`}
        style={{ display: 'block' }}
      >
        <text x={left} y={14} fill="var(--muted)" fontSize={12}>
          kg
        </text>

        {ticks.map((value) => (
          <g key={value}>
            <line
              x1={left}
              x2={right}
              y1={y(value)}
              y2={y(value)}
              stroke="var(--line)"
            />
            <text
              x={left - 8}
              y={y(value) + 4}
              textAnchor="end"
              fill="var(--muted)"
              fontSize={12}
            >
              {value.toFixed(1)}
            </text>
          </g>
        ))}

        {series.map((item) => (
          <g key={item.key}>
            <path
              d={pathFor(item.key)}
              fill="none"
              stroke={item.color}
              strokeWidth={2}
              strokeDasharray={item.dashed ? '6 4' : undefined}
            />

            {data.map((record, index) => {
              const value = record[item.key];

              if (value == null || !Number.isFinite(value)) return null;

              return (
                <circle
                  key={record.inbodyid}
                  cx={x(index)}
                  cy={y(value)}
                  r={3}
                  fill={item.color}
                >
                  <title>
                    {record.recorddate}：{item.label} {value.toFixed(1)} kg
                  </title>
                </circle>
              );
            })}
          </g>
        ))}

        <text
          x={left}
          y={bottom + 24}
          fill="var(--muted)"
          fontSize={12}
        >
          {data[0].recorddate}
        </text>

        {first !== last && (
          <text
            x={right}
            y={bottom + 24}
            textAnchor="end"
            fill="var(--muted)"
            fontSize={12}
          >
            {data[data.length - 1].recorddate}
          </text>
        )}
      </svg>
    </div>
  );
}