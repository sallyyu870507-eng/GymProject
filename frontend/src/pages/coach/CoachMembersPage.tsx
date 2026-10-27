import { useState } from 'react';
import { coachApi } from '../../api/coach';
import type { CoachMemberUpdateRequest, MemberListItem } from '../../api/types';
import { FormDialog, type FieldDef } from '../../components/FormDialog';
import { MemberTable } from '../../components/MemberTable';
import { AsyncView, Card, PageHeader } from '../../components/ui';
import { useApi } from '../../hooks/useApi';
import { useDebounced } from '../../hooks/useDebounced';

const PAGE_SIZE = 10;

/** CoachMemberUpdateDTO：教練只能改姓名、手機、Email */
const FIELDS: FieldDef<CoachMemberUpdateRequest>[] = [
  { name: 'name', label: '姓名', required: true },
  { name: 'phone', label: '手機', type: 'tel', required: true },
  { name: 'email', label: 'Email', type: 'email' },
];

/** 教練：我的學員（CoachMemberController /api/coach/members），只列出有買自己課程的會員 */
export default function CoachMembersPage() {
  const [page, setPage] = useState(0);
  const [keywordInput, setKeywordInput] = useState('');
  const keyword = useDebounced(keywordInput.trim());
  const [editing, setEditing] = useState<MemberListItem | null>(null);
  const [notice, setNotice] = useState<string>();

  const members = useApi((s) => coachApi.members({ page, size: PAGE_SIZE, keyword }, s), [page, keyword]);

  return (
    <div className="page">
      <PageHeader title="我的學員" back={{ to: '/trainer', label: '返回今日課表' }} />

      <Card
        title="學員清單"
        subtitle="只顯示有購買你課程的學員，堂數為你的課程剩餘堂數"
        action={
          <input
            className="search"
            type="search"
            placeholder="搜尋姓名、手機…"
            value={keywordInput}
            onChange={(e) => {
              setKeywordInput(e.target.value);
              setPage(0);
            }}
            aria-label="搜尋學員"
          />
        }
      >
        {notice && (
          <p className="notice notice-ok" role="status">
            {notice}
          </p>
        )}
        <AsyncView state={members} minHeight={320}>
          {(data) => (
            <MemberTable
              data={data}
              onPage={setPage}
              showStatus={false}
              actions={(m) => (
                <button type="button" className="btn btn-small" onClick={() => setEditing(m)}>
                  編輯
                </button>
              )}
            />
          )}
        </AsyncView>
      </Card>

      {editing && (
        <FormDialog<CoachMemberUpdateRequest>
          title={`編輯學員：${editing.name}`}
          fields={FIELDS}
          initial={coachApi.getMember(editing.memberid)}
          onClose={() => setEditing(null)}
          onSubmit={async (v) => {
            const res = await coachApi.updateMember(editing.memberid, v);
            setNotice(res.message ?? '會員資料更新成功');
            setEditing(null);
            members.reload();
          }}
        />
      )}
    </div>
  );
}
