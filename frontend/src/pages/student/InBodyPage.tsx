import { memberApi } from '../../api/member';
import { InBodyChart } from '../../components/charts';
import { AsyncView, Card, PageHeader, StatTile } from '../../components/ui';
import { useApi } from '../../hooks/useApi';
import { fmtDate, fmtSigned } from '../../utils/format';
import { INBODY_METRICS, metricValue, summarizeInBody, type InBodyMetric } from '../../utils/stats';

/** inbodyrecords 有 weight / bodyfatpct / musclemass；fatmass 由前端換算 */
const METRICS: InBodyMetric[] = ['weight', 'musclemass', 'bodyfatpct', 'fatmass'];

export default function InBodyPage() {
  const inbody = useApi((s) => memberApi.inbody(s), []);

  return (
    <div className="page">
      <PageHeader title="InBody 分析" />

      <AsyncView state={inbody} minHeight={110}>
        {(rows) => {
          const s = summarizeInBody(rows);
          if (!s.latest) return <p className="muted">還沒有 InBody 檢測紀錄</p>;
          return (
            <div className="tiles">
              {METRICS.map((m) => {
                const meta = INBODY_METRICS[m];
                const tone = (v: number) =>
                  v === 0 ? undefined : (meta.goodWhen === 'up') === v > 0 ? 'tone-good' : 'tone-bad';
                const dPrev = s.deltaPrev(m);
                const dFirst = s.deltaFirst(m);
                return (
                  <StatTile
                    key={m}
                    label={meta.label}
                    value={metricValue(s.latest, m).toFixed(meta.digits)}
                    unit={meta.unit}
                    hint={
                      <>
                        較上次 <span className={tone(dPrev)}>{fmtSigned(dPrev, meta.digits)}</span> · 較首次{' '}
                        <span className={tone(dFirst)}>{fmtSigned(dFirst, meta.digits)}</span>
                      </>
                    }
                  />
                );
              })}
            </div>
          );
        }}
      </AsyncView>

      <div className="grid-2">
        <Card title="體重與肌肉量" subtitle="每次 InBody 檢測，單位 kg">
          <AsyncView state={inbody} minHeight={240}>
            {(rows) => <InBodyChart rows={rows} metrics={['weight', 'musclemass']} />}
          </AsyncView>
        </Card>
        <Card title="體脂率" subtitle="每次 InBody 檢測，單位 %">
          <AsyncView state={inbody} minHeight={240}>
            {(rows) => <InBodyChart rows={rows} metrics={['bodyfatpct']} />}
          </AsyncView>
        </Card>
      </div>

      <Card title="檢測紀錄" subtitle="最新在上；體脂肪重 = 體重 × 體脂率">
        <AsyncView state={inbody} minHeight={200}>
          {(rows) => (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>檢測日期</th>
                    <th className="num">體重 kg</th>
                    <th className="num">肌肉量 kg</th>
                    <th className="num">體脂率 %</th>
                    <th className="num">體脂肪重 kg</th>
                  </tr>
                </thead>
                <tbody>
                  {[...rows]
                    .sort((a, b) => b.recorddate.localeCompare(a.recorddate))
                    .map((r) => (
                      <tr key={r.inbodyid}>
                        <td>{fmtDate(r.recorddate)}</td>
                        <td className="num">{Number(r.weight).toFixed(1)}</td>
                        <td className="num">{Number(r.musclemass).toFixed(1)}</td>
                        <td className="num">{Number(r.bodyfatpct).toFixed(1)}</td>
                        <td className="num">{metricValue(r, 'fatmass').toFixed(1)}</td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>
          )}
        </AsyncView>
      </Card>
    </div>
  );
}
