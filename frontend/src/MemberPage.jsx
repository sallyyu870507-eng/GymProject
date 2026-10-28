import { useEffect, useRef, useState } from 'react'
import { request } from './api.js'

const emptyPage = {
  members: [],
  totalPages: 0,
  totalElements: 0,
  currentPage: 0,
  pageSize: 10,
}
const fieldNames = {
  username: '帳號',
  password: '密碼',
  name: '姓名',
  gender: '性別',
  phone: '手機',
  email: 'Email',
  birthday: '生日',
}

export default function MemberPage({ role, onExpired }) {
  const admin = role === 'admin'
  const defaultStatus = admin ? 'active' : 'all'
  const base = admin ? '/api/admin/members' : '/api/coach/members'
  const [keyword, setKeyword] = useState('')
  const [status, setStatus] = useState(defaultStatus)
  const [query, setQuery] = useState({
    keyword: '',
    status: defaultStatus,
    page: 0,
  })
  const [data, setData] = useState(emptyPage)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [refresh, setRefresh] = useState(0)
  const [modal, setModal] = useState(null)
  const [changing, setChanging] = useState(false)  //負責更新停用按鈕的狀態
  const actionLock = useRef(false) //操作鎖防止停用/恢復的請求重複送出
  async function api(path, options) {
    try {
      return await request(path, options)
    } catch (e) {
      if (e.status === 401) onExpired()
      throw e
    }
  }
  useEffect(() => {
    const controller = new AbortController()
    setLoading(true)
    setError('')
    const params = new URLSearchParams({
      page: String(query.page),
      size: '10',
      keyword: query.keyword,
    })
    if (admin) params.set('status', query.status)
    api(`${base}?${params}`, { signal: controller.signal })
      .then((result) => {
        if (controller.signal.aborted) return
        if (query.page > 0 && query.page >= result.totalPages) {
          setQuery((q) => ({ ...q, page: Math.max(0, result.totalPages - 1) }))
          return
        }
        setData(result)
      })
      .catch((e) => {
        if (!controller.signal.aborted) {
          setData(emptyPage)
          setError(e.message)
        }
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false)
      })
    return () => controller.abort()
  }, [query, refresh, base, admin])
  function search(e) {
    e.preventDefault()
    setMessage('')
    setQuery({ keyword: keyword.trim(), status, page: 0 })
  }
  function clear() {
    setKeyword('')
    setStatus(defaultStatus)
    setMessage('')
    setQuery({ keyword: '', status: defaultStatus, page: 0 })
  }
  function saved(text) {
    setModal(null)
    setMessage(text)
    setRefresh((v) => v + 1)
  }
  async function changeStatus(member) {
    if (actionLock.current) return
    const active = member.status?.trim() === 'active'
    if (
      !window.confirm(
        `確定要${active ? '停用' : '恢復'}「${member.name}」的會員帳號嗎？`,
      )
    )
      return
    actionLock.current = true
    setChanging(true)
    setError('')
    setMessage('')
    try {
      await api(
        active
          ? `${base}/del/${member.accountid}`
          : `${base}/${member.accountid}/reactivate`,
        { method: active ? 'DELETE' : 'PATCH' },
      )
      saved(active ? '帳號停用成功' : '會員恢復成功')
    } catch (e) {
      setError(e.message)
    } finally {
      actionLock.current = false
      setChanging(false)
    }
  }
  const count = data.members.length
  return (
    <>
      <div className="page-title">
        <h1>{admin ? '會員管理' : '學員管理'}</h1>
        {admin && (
          <button
            className="primary"
            disabled={changing}
            onClick={() => setModal({ type: 'create' })}
          >
            新增會員
          </button>
        )}
      </div>
      <form className="search-bar" onSubmit={search}>
        <input
          aria-label="搜尋姓名、會員編號或電話"
          placeholder="輸入姓名、會員編號或電話"
          value={keyword}
          onChange={(e) => setKeyword(e.target.value)}
        />
        {admin && (
          <select
            aria-label="會員狀態"
            value={status}
            onChange={(e) => setStatus(e.target.value)}
          >
            <option value="all">全部狀態</option>
            <option value="active">啟用中</option>
            <option value="inactive">已停用</option>
          </select>
        )}
        <button className="primary" type="submit" disabled={loading}>
          搜尋
        </button>
        <button type="button" onClick={clear}>
          清除
        </button>
      </form>
      {error && (
        <p role="alert" className="error">
          {error} <button onClick={() => setRefresh((v) => v + 1)}>重試</button>
        </p>
      )}
      {message && (
        <p role="status" className="success">
          {message}
        </p>
      )}
      <section
        className="table-card"
        aria-label={admin ? '會員清單' : '學員清單'}
        aria-busy={loading}
      >
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>會員編號</th>
                <th>姓名</th>
                <th>電話</th>
                <th>狀態</th>
                <th>課程剩餘堂數</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="6" className="empty" role="status">
                    載入中…
                  </td>
                </tr>
              ) : !count ? (
                <tr>
                  <td colSpan="6" className="empty">
                    {error ? '資料載入失敗' : '沒有符合條件的資料'}
                  </td>
                </tr>
              ) : (
                data.members.map((member) => (
                  <tr
                    key={member.memberid}
                    className={
                      admin && member.status?.trim() === 'inactive'
                        ? 'member-inactive'
                        : undefined
                    }
                  >
                    <td>{member.memberno}</td>
                    <td>{member.name}</td>
                    <td>{member.phone || '—'}</td>
                    <td>
                      <span
                        className={`status ${member.status?.trim() === 'active' ? '' : 'inactive'}`}
                      >
                        {member.status?.trim() === 'active' ? '啟用' : '停用'}
                      </span>
                    </td>
                    <td>
                      {admin
                        ? member.courses?.length
                          ? member.courses.map((course, index) => (
                              <div key={index}>
                                {course.coursename}{' - '}{course.name}：{course.remainingsessions}{' '}
                                堂
                              </div>
                            ))
                          : '無課程'
                        : (member.courses || [])
                            .map(
                              (c) =>
                                `${c.coursename} ${c.remainingsessions} 堂`,
                            )
                            .join('｜') || '尚無課程'}
                    </td>
                    <td>
                      <div className="actions">
                        <button
                          className="primary"
                          disabled={changing}
                          onClick={() => setModal({ type: 'edit', member })}
                        >
                          查看／編輯
                        </button>
                        {admin && (
                          <>
                            <button
                              className="purchase"
                              disabled={
                                changing || member.status?.trim() !== 'active'
                              }
                              onClick={() =>
                                setModal({ type: 'purchase', member })
                              }
                            >
                              新增購課
                            </button>
                            <button
                              className={
                                member.status?.trim() === 'active'
                                  ? 'danger'
                                  : 'soft'
                              }
                              disabled={changing}
                              onClick={() => changeStatus(member)}
                            >
                              {member.status?.trim() === 'active'
                                ? '停用'
                                : '恢復'}
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
        <div className="pagination">
          <span>
            顯示 {count && !loading ? data.currentPage * data.pageSize + 1 : 0}–
            {loading ? 0 : data.currentPage * data.pageSize + count} 筆，共{' '}
            {data.totalElements} 筆
          </span>
          <div className="actions">
            <button
              aria-label="上一頁"
              disabled={loading || changing || !data.hasPrev}
              onClick={() => setQuery((q) => ({ ...q, page: q.page - 1 }))}
            >
              ‹
            </button>
            <span className="page-number">
              {data.totalPages ? data.currentPage + 1 : 0} / {data.totalPages}
            </span>
            <button
              aria-label="下一頁"
              disabled={loading || changing || !data.hasNext}
              onClick={() => setQuery((q) => ({ ...q, page: q.page + 1 }))}
            >
              ›
            </button>
          </div>
        </div>
      </section>
      {modal && (
        <MemberDialog
          key={`${modal.type}-${modal.member?.memberid || ''}`}
          modal={modal}
          admin={admin}
          base={base}
          api={api}
          onClose={() => setModal(null)}
          onSaved={saved}
        />
      )}
    </>
  )
}

function MemberDialog({ modal, admin, base, api, onClose, onSaved }) {
  const dialog = useRef(null)
  const lock = useRef(false)
  const [form, setForm] = useState({})
  const [loading, setLoading] = useState(modal.type !== 'create')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [courses, setCourses] = useState([])
  const [coaches, setCoaches] = useState([])
  const [courseid, setCourseid] = useState('')
  const [coachid, setCoachid] = useState('')
  const [coachLoading, setCoachLoading] = useState(false)
  const [coachesError, setCoachesError] = useState('')
  const readOnly = modal.type === 'view'
  const purchase = modal.type === 'purchase'
  const create = modal.type === 'create'
  useEffect(() => {
    dialog.current.showModal()
    const controller = new AbortController()
    if (!create)
      api(
        purchase
          ? '/api/admin/purchases/courses'
          : `${base}/${modal.member.memberid}`,
        { signal: controller.signal },
      )
        .then((result) => {
          if (!controller.signal.aborted) {
            if (purchase) setCourses(result)
            else setForm(result)
          }
        })
        .catch((e) => {
          if (!controller.signal.aborted) setError(e.message)
        })
        .finally(() => {
          if (!controller.signal.aborted) setLoading(false)
        })
    return () => controller.abort()
  }, [])
  useEffect(() => {
    if (!purchase || !courseid) return
    const controller = new AbortController()
    setCoachLoading(true)
    setCoachesError('')
    api(`/api/admin/purchases/courses/${courseid}/coaches`, {
      signal: controller.signal,
    })
      .then((result) => {
        if (!controller.signal.aborted) {
          setCoaches(result)
          if (!result.length) setCoachesError('此課程目前沒有可授課教練。')
        }
      })
      .catch((e) => {
        if (!controller.signal.aborted) setCoachesError(e.message)
      })
      .finally(() => {
        if (!controller.signal.aborted) setCoachLoading(false)
      })
    return () => controller.abort()
  }, [courseid])
  const fields = create
    ? ['username', 'password', 'name', 'gender', 'phone', 'email', 'birthday']
    : admin
      ? ['username', 'name', 'phone', 'email']
      : ['name', 'phone', 'email']
  async function submit(e) {
    e.preventDefault()
    if (lock.current || loading) return
    if (
      purchase &&
      !window.confirm(
        `確定為「${modal.member.name}」新增此筆 10 堂購課紀錄嗎？`,
      )
    )
      return
    lock.current = true
    setBusy(true)
    setError('')
    try {
      const payload = purchase
        ? { courseid: Number(courseid), coachid: Number(coachid) }
        : Object.fromEntries(
            fields.map((key) => [key, String(form[key] || '').trim()]),
          )
      const path = purchase
        ? `/api/admin/purchases/${modal.member.memberid}/purchases`
        : create
          ? base
          : `${base}/update/${modal.member.memberid}`
      await api(path, {
        method: purchase || create ? 'POST' : 'PUT',
        body: JSON.stringify(payload),
      })
      onSaved(purchase ? '購課成功' : create ? '新增會員成功' : '資料更新成功')
    } catch (e) {
      setError(e.message)
    } finally {
      lock.current = false
      setBusy(false)
    }
  }
  const selected = courses.find((c) => String(c.courseid) === courseid)
  const money = (value) =>
    Number(value || 0).toLocaleString('zh-TW', {
      style: 'currency',
      currency: 'TWD',
      maximumFractionDigits: 2,
    })
  return (
    <dialog
      className="member-dialog"
      ref={dialog}
      aria-labelledby="dialog-title"
      onCancel={(e) => {
        e.preventDefault()
        if (!busy) onClose()
      }}
    >
      <h2 id="dialog-title">
        {purchase
          ? '新增購課'
          : create
            ? '新增會員'
            : readOnly
              ? '查看資料'
              : admin
                ? '查看／編輯會員'
                : '查看／編輯學員'}
        {modal.member ? `｜${modal.member.name}` : ''}
      </h2>
      {loading && <p role="status">載入中…</p>}
      {error && (
        <p className="error" role="alert">
          {error}
        </p>
      )}
      {create && (
        <p className="registration-note">
          標示「必填」的欄位皆須填寫，Email 為選填。
        </p>
      )}
      <form onSubmit={submit}>
        <fieldset disabled={loading || busy || readOnly}>
          {purchase ? (
            <>
              <label>
                課程
                <select
                  required
                  value={courseid}
                  onChange={(e) => {
                    setCourseid(e.target.value)
                    setCoachid('')
                    setCoaches([])
                    setCoachesError('')
                    setCoachLoading(!!e.target.value)
                  }}
                >
                  <option value="">請選擇課程</option>
                  {courses.map((c) => (
                    <option key={c.courseid} value={c.courseid}>
                      {c.coursename}
                    </option>
                  ))}
                </select>
              </label>
              {!loading && !courses.length && (
                <p className="muted">目前沒有可購買的課程。</p>
              )}
              <label>
                教練
                <select
                  required
                  disabled={!courseid || coachLoading}
                  value={coachid}
                  onChange={(e) => setCoachid(e.target.value)}
                >
                  <option value="">
                    {coachLoading ? '載入中…' : '請選擇教練'}
                  </option>
                  {coaches.map((c) => (
                    <option key={c.coachid} value={c.coachid}>
                      {c.coachname}（{c.coachno}）
                    </option>
                  ))}
                </select>
              </label>
              {coachesError && (
                <p className="error" role="alert">
                  {coachesError}
                </p>
              )}
              <div className="purchase-summary">
                <p>方案：固定 10 堂</p>
                <p>單堂價格：{money(selected?.price)}</p>
                <strong>
                  總金額：{money(Number(selected?.price || 0) * 10)}
                </strong>
              </div>
            </>
          ) : (
            fields.map((key) => (
              <label key={key}>
                <span>
                  {fieldNames[key]}
                  {create && (
                    <span
                      className={
                        key === 'email' ? 'optional-label' : 'required-label'
                      }
                    >
                      {key === 'email' ? '（選填）' : '（必填）'}
                    </span>
                  )}
                </span>
                {key === 'gender' ? (
                  <select
                    required
                    value={form[key] || ''}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, [key]: e.target.value }))
                    }
                  >
                    <option value="">請選擇</option>
                    <option value="male">男</option>
                    <option value="female">女</option>
                  </select>
                ) : (
                  <input
                    value={form[key] || ''}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, [key]: e.target.value }))
                    }
                    required={key !== 'email'}
                    type={
                      key === 'password'
                        ? 'password'
                        : key === 'birthday'
                          ? 'date'
                          : key === 'email'
                            ? 'email'
                            : key === 'phone'
                              ? 'tel'
                              : 'text'
                    }
                    pattern={
                      key === 'username'
                        ? '[A-Za-z0-9]{4,20}'
                        : key === 'phone'
                          ? '09[0-9]{8}'
                          : undefined
                    }
                    title={
                      key === 'username'
                        ? '4–20 位英文字母或數字'
                        : key === 'phone'
                          ? '09 開頭的 10 位手機號碼'
                          : undefined
                    }
                    minLength={key === 'password' ? 4 : undefined}
                    maxLength={key === 'password' ? 50 : undefined}
                    autoComplete={
                      key === 'password' ? 'new-password' : undefined
                    }
                    max={
                      key === 'birthday'
                        ? new Date(Date.now() - 86400000).toLocaleDateString(
                            'en-CA',
                          )
                        : undefined
                    }
                  />
                )}
              </label>
            ))
          )}
        </fieldset>
        {(readOnly || modal.type === 'edit') && (
          <section className="course-details">
            <h3>課程剩餘堂數</h3>
            {modal.member.courses?.length ? (
              modal.member.courses.map((c, i) => (
                <p key={`${c.courseid}-${i}`}>
                  {c.coursename}{' - '}{c.name}：{c.remainingsessions} 堂
                </p>
              ))
            ) : (
              <p>尚無課程</p>
            )}
          </section>
        )}
        <div className="dialog-actions">
          <button type="button" disabled={busy} onClick={onClose}>
            {readOnly ? '關閉' : '取消'}
          </button>
          {!readOnly && (
            <button
              type="submit"
              className="primary"
              disabled={
                loading ||
                busy ||
                (purchase && (!coachid || coachLoading || !!coachesError)) ||
                (!create && !purchase && !Object.keys(form).length)
              }
            >
              {busy ? '處理中…' : purchase ? '確認購課' : '儲存'}
            </button>
          )}
        </div>
      </form>
    </dialog>
  )
}
