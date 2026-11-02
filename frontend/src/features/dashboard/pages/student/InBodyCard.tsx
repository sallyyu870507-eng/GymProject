import { useEffect, useState } from 'react';
import { request } from '../../../../api.js';
import { Card } from '../../components/ui';
import InBodyChart from './InBodyChart';


type InBodyRecord = {
  inbodyid: number;
  recorddate: string | null;
  weight: number | null;
  bodyfatpct: number | null;
  musclemass: number | null;
};

function metric(value: number | null | undefined) {
  return value == null || !Number.isFinite(value)
    ? '—'
    : value.toFixed(1);
}

export default function InBodyCard() {
  const [records, setRecords] = useState<InBodyRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    const controller = new AbortController();

    setLoading(true);
    setError('');

    request('/api/member/inbody', { signal: controller.signal })
      .then((data) => {
        if (controller.signal.aborted) return;
        if (!Array.isArray(data)) {
          throw new Error('InBody 回傳格式不正確');
        }
        setRecords(data);
      })
      .catch((failure: unknown) => {
        if (controller.signal.aborted) return;
        setRecords([]);
        setError(
          failure instanceof Error
            ? failure.message
            : 'InBody 資料讀取失敗',
        );
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });

    return () => controller.abort();
  }, [attempt]);

  // 後端依檢測日期由舊到新排列。
  const latest = records.at(-1);
  const fatMass =
    latest?.weight != null && latest.bodyfatpct != null
      ? latest.weight * latest.bodyfatpct / 100
      : null;

  return (
    <Card
      title="INBODY 分析"
      footer={
        <button
          type="button"
          className="btn"
          disabled={loading}
          onClick={() => setAttempt((value) => value + 1)}
        >
          重新讀取
        </button>
      }
    >
      {loading ? (
        <p role="status">InBody 資料載入中…</p>
      ) : error ? (
        <p role="alert">{error}</p>
      ) : !latest ? (
        <p className="muted">目前尚無 InBody 檢測紀錄。</p>
      ) : (
        <>
          <p className="muted">
            最新檢測：{latest.recorddate || '未提供日期'}
          </p>

          <div className="member-dashboard-stats member-inbody-stats">
            <div className="member-dashboard-stat"><span className="member-dashboard-stat-label">體重</span><strong>{metric(latest.weight)}<small>kg</small></strong></div>
            <div className="member-dashboard-stat"><span className="member-dashboard-stat-label">肌肉量</span><strong>{metric(latest.musclemass)}<small>kg</small></strong></div>
            <div className="member-dashboard-stat"><span className="member-dashboard-stat-label">體脂率</span><strong>{metric(latest.bodyfatpct)}<small>%</small></strong></div>
            <div className="member-dashboard-stat"><span className="member-dashboard-stat-label">體脂肪重（估算）</span><strong>{metric(fatMass)}<small>kg</small></strong></div>
          </div>

          <InBodyChart records={records} />
        </>
      )}
    </Card>
  );
}
