import { catalogApi, memberApi } from '../../api/member';
import { CourseProgress } from '../../components/member';
import { AsyncView, Card, PageHeader, StatTile, StatusPill } from '../../components/ui';
import { useApi } from '../../hooks/useApi';
import { fmtNumber } from '../../utils/format';

export default function CoursesPage() {
  const courses = useApi((s) => memberApi.courses(s), []);
  const catalog = useApi((s) => catalogApi.list(s), []);

  return (
    <div className="page">
      <PageHeader title="課程管理" />

      <AsyncView state={courses} minHeight={110}>
        {(list) => {
          const remaining = list.reduce((s, c) => s + c.remainingsessions, 0);
          const hasTotal = list.every((c) => c.totalsessions !== undefined);
          const total = list.reduce((s, c) => s + (c.totalsessions ?? 0), 0);
          return (
            <div className="tiles">
              <StatTile label="有效課程" value={list.length} unit="門" hint="剩餘堂數 > 0" />
              <StatTile label="剩餘總堂數" value={remaining} unit="堂" hint="所有已購課程合計" />
              {hasTotal && <StatTile label="已使用堂數" value={total - remaining} unit="堂" hint={`共購買 ${total} 堂`} />}
            </div>
          );
        }}
      </AsyncView>

      <Card title="我的課程" subtitle="對應 GET /members/courses，進度條為已使用比例">
        <AsyncView state={courses} minHeight={160}>
          {(list) =>
            list.length ? (
              <div className="course-grid">
                {list.map((c) => (
                  <CourseProgress key={c.membercourseid} course={c} />
                ))}
              </div>
            ) : (
              <p className="muted">目前沒有有效課程</p>
            )
          }
        </AsyncView>
      </Card>

      <Card title="課程目錄" subtitle="course 資料表；授課教練來自 coachcourse">
        <AsyncView state={catalog} minHeight={200}>
          {(rows) => (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>課程</th>
                    <th>類型</th>
                    <th>說明</th>
                    <th className="num">每堂分鐘</th>
                    <th className="num">價格 NT$</th>
                    <th>授課教練</th>
                    <th>狀態</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((r) => (
                    <tr key={r.courseid}>
                      <td>{r.coursename}</td>
                      <td>{r.coursetype}</td>
                      <td className="wrap">{r.description}</td>
                      <td className="num">{r.durationmin}</td>
                      <td className="num">{fmtNumber(r.price)}</td>
                      <td>{r.coaches?.join('、') ?? '—'}</td>
                      <td>
                        <StatusPill status={r.status.trim()} />
                      </td>
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
