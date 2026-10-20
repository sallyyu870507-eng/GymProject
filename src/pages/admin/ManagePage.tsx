import { useState } from 'react';
import { adminApi } from '../../api/admin';
import type { MemberListItem, MemberStatusFilter, MemberUpdateRequest, RegisterRequest } from '../../api/types';
import { useAuth } from '../../auth/AuthContext';
import { FormDialog, type FieldDef } from '../../components/FormDialog';
import { MemberTable } from '../../components/MemberTable';
import { AsyncView, Card, StatTile } from '../../components/ui';
import { useApi } from '../../hooks/useApi';
import { useDebounced } from '../../hooks/useDebounced';

const PAGE_SIZE = 10;

const STATUS_FILTERS: [MemberStatusFilter, string][] = [
  ['all', '全部'],
  ['active', '啟用中'],
  ['inactive', '已停用'],
];

/** RegisterDTO 的欄位與驗證規則 */
const CREATE_FIELDS: FieldDef<RegisterRequest>[] = [
  { name: 'username', label: '帳號', required: true, hint: '4~20 位英文字母或數字' },
  { name: 'password', label: '密碼', type: 'password', required: true, hint: '至少 4 個字元' },
  { name: 'name', label: '姓名', required: true },
  {
    name: 'gender',
    label: '性別',
    type: 'select',
    options: [
      { value: '', label: '不指定' },
      { value: '男', label: '男' },
      { value: '女', label: '女' },
    ],
  },
  { name: 'phone', label: '手機', type: 'tel', required: true, placeholder: '0912345678' },
  { name: 'email', label: 'Email', type: 'email' },
  { name: 'birthday', label: '生日', type: 'date', required: true },
];

/** MemberUpdateDTO 可以修改的欄位 */
const EDIT_FIELDS: FieldDef<MemberUpdateRequest>[] = [
  { name: 'username', label: '帳號', required: true, hint: '4~20 位英文字母或數字' },
  { name: 'name', label: '姓名', required: true },
  { name: 'phone', label: '手機', type: 'tel', required: true },
  { name: 'email', label: 'Email', type: 'email' },
];

const EMPTY_REGISTER: RegisterRequest = {
  username: '',
  password: '',
  name: '',
  gender: '',
  phone: '',
  email: '',
  birthday: '',
};

type Dialog = { kind: 'create' } | { kind: 'edit'; member: MemberListItem } | null;

/** 管理員：會員管理（AdminController /api/admin/members） */
export default function ManagePage() {
  const { user } = useAuth();
  const [page, setPage] = useState(0);
  const [status, setStatus] = useState<MemberStatusFilter>('all');
  const [keywordInput, setKeywordInput] = useState('');
  const keyword = useDebounced(keywordInput.trim());
  const [dialog, setDialog] = useState<Dialog>(null);
  const [notice, setNotice] = useState<{ tone: 'ok' | 'bad'; text: string }>();
  const [busyId, setBusyId] = useState<number>();

  const members = useApi(
    (s) => adminApi.members({ page, size: PAGE_SIZE, status, keyword }, s),
    [page, status, keyword],
  );

  // 換篩選條件就回到第一頁
  const changeStatus = (s: MemberStatusFilter) => {
    setStatus(s);
    setPage(0);
  };
  const changeKeyword = (k: string) => {
    setKeywordInput(k);
    setPage(0);
  };

  const done = (text: string) => {
    setNotice({ tone: 'ok', text });
    setDialog(null);
    members.reload();
  };

  const toggleStatus = async (m: MemberListItem) => {
    const deactivate = m.status !== 'inactive';
    if (deactivate && !window.confirm(`確定要停用 ${m.name}（${m.memberno}）？停用後無法登入。`)) return;
    setBusyId(m.accountid);
    try {
      const res = deactivate ? await adminApi.deactivate(m.accountid) : await adminApi.reactivate(m.accountid);
      setNotice({ tone: 'ok', text: res.message ?? (deactivate ? '帳號停用成功' : '會員恢復成功') });
      members.reload();
    } catch (err) {
      setNotice({ tone: 'bad', text: (err as Error).message });
    } finally {
      setBusyId(undefined);
    }
  };

  return (
    <div className="page">
      <h1 className="hello">你好，{user?.name}</h1>

      <div className="tiles">
        <StatTile
          label={status === 'all' ? '會員總數' : status === 'active' ? '啟用中會員' : '已停用會員'}
          value={members.data?.totalElements ?? '—'}
          unit="位"
          hint={keyword ? `搜尋「${keyword}」` : 'GET /api/admin/members'}
        />
        <StatTile
          label="目前頁數"
          value={members.data ? `${members.data.currentPage + 1} / ${Math.max(1, members.data.totalPages)}` : '—'}
          hint={`每頁 ${PAGE_SIZE} 筆`}
        />
      </div>

      <Card
        title="會員清單"
        subtitle="可依狀態篩選、以姓名或手機搜尋"
        action={
          <button type="button" className="btn btn-primary" onClick={() => setDialog({ kind: 'create' })}>
            ＋ 新增會員
          </button>
        }
      >
        <div className="toolbar">
          <div className="chips" role="group" aria-label="依狀態篩選">
            {STATUS_FILTERS.map(([value, label]) => (
              <button key={value} type="button" className="chip" aria-pressed={status === value} onClick={() => changeStatus(value)}>
                {label}
              </button>
            ))}
          </div>
          <input
            className="search"
            type="search"
            placeholder="搜尋姓名、手機…"
            value={keywordInput}
            onChange={(e) => changeKeyword(e.target.value)}
            aria-label="搜尋會員"
          />
        </div>

        {notice && (
          <p className={`notice notice-${notice.tone}`} role="status">
            {notice.text}
          </p>
        )}

        <AsyncView state={members} minHeight={360}>
          {(data) => (
            <MemberTable
              data={data}
              onPage={setPage}
              actions={(m) => (
                <>
                  <button type="button" className="btn btn-small" onClick={() => setDialog({ kind: 'edit', member: m })}>
                    編輯
                  </button>
                  <button
                    type="button"
                    className={`btn btn-small ${m.status === 'inactive' ? '' : 'btn-danger'}`}
                    disabled={busyId === m.accountid}
                    onClick={() => void toggleStatus(m)}
                  >
                    {m.status === 'inactive' ? '恢復' : '停用'}
                  </button>
                </>
              )}
            />
          )}
        </AsyncView>
      </Card>

      {dialog?.kind === 'create' && (
        <FormDialog<RegisterRequest>
          title="新增會員"
          fields={CREATE_FIELDS}
          initial={EMPTY_REGISTER}
          submitLabel="新增"
          onClose={() => setDialog(null)}
          onSubmit={async (v) => {
            const res = await adminApi.createMember(v);
            done(res.message ?? '新增會員成功');
          }}
        />
      )}

      {dialog?.kind === 'edit' && (
        <FormDialog<MemberUpdateRequest>
          title={`編輯會員：${dialog.member.name}（${dialog.member.memberno}）`}
          fields={EDIT_FIELDS}
          initial={adminApi.getMember(dialog.member.memberid)}
          onClose={() => setDialog(null)}
          onSubmit={async (v) => {
            const res = await adminApi.updateMember(dialog.member.memberid, v);
            done(res.message ?? '會員資料更新成功');
          }}
        />
      )}
    </div>
  );
}
