import { memberApi } from '../../api/member';
import { AttendanceChart } from '../../components/charts';
import { MemberAvatar } from '../../components/member';
import { AsyncView, Card, PageHeader, StatTile, StatusPill } from '../../components/ui';
import { useApi } from '../../hooks/useApi';
import { fmtDate } from '../../utils/format';

/** 會員管理：資料來自 member 資料表（GET /members/profile）與 attendance 統計 */
export default function ProfilePage() {
  const profile = useApi((s) => memberApi.profile(s), []);
  const attendance = useApi((s) => memberApi.attendance(s), []);
  const courses = useApi((s) => memberApi.courses(s), []);

  const weeks = attendance.data ?? [];
  const total = weeks.reduce((s, w) => s + w.checkins, 0);
  const remaining = courses.data?.reduce((s, c) => s + c.remainingsessions, 0);

  return (
    <div className="page">
      <PageHeader title="會員管理" />

      <div className="tiles">
        <StatTile label="會員編號" value={profile.data?.memberno ?? '—'} hint="member.memberno" />
        <StatTile
          label="帳號狀態"
          value={profile.data ? (profile.data.status === 'active' ? '啟用中' : '已停用') : '—'}
          tone={profile.data?.status === 'inactive' ? 'bad' : undefined}
        />
        <StatTile label="剩餘總堂數" value={remaining ?? '—'} unit="堂" hint="所有已購課程合計" />
        <StatTile
          label={`近 ${weeks.length || 12} 週到館`}
          value={attendance.data ? total : '—'}
          unit="次"
          hint={weeks.length ? `平均每週 ${(total / weeks.length).toFixed(1)} 次` : undefined}
        />
      </div>

      <div className="grid-2">
        <Card title="會員資料" subtitle="目前登入會員">
          <AsyncView state={profile} minHeight={200}>
            {(m) => (
              <div className="member-summary">
                <MemberAvatar name={m.name} url={m.avatarurl} />
                <dl className="meta meta-lg">
                  <dt>姓名</dt>
                  <dd>{m.name}</dd>
                  <dt>會員編號</dt>
                  <dd>{m.memberno}</dd>
                  <dt>性別</dt>
                  <dd>{m.gender || '—'}</dd>
                  <dt>生日</dt>
                  <dd>{fmtDate(m.birthday)}</dd>
                  <dt>手機</dt>
                  <dd>{m.phone}</dd>
                  <dt>Email</dt>
                  <dd>{m.email || '—'}</dd>
                  <dt>狀態</dt>
                  <dd>
                    <StatusPill status={m.status} />
                  </dd>
                </dl>
              </div>
            )}
          </AsyncView>
        </Card>

        <Card title="每週到館次數" subtitle="依 attendance 簽到時間統計，近 12 週">
          <AsyncView state={attendance} minHeight={220}>
            {(rows) => <AttendanceChart rows={rows} />}
          </AsyncView>
        </Card>
      </div>
    </div>
  );
}
