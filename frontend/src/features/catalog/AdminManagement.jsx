import { useEffect, useRef, useState } from 'react'
import { adminRequest, loadAdminData, saveCourseCoaches } from './adminApi'
import './AdminManagement.css'

function RelationTags({ names, unit }) {
  const [expanded, setExpanded] = useState(false)
  return <div className="admin-tags">
    {!names.length && '尚未指派'}
    {(expanded ? names : names.slice(0, 2)).map((name, index) => <span key={index}>{name}</span>)}
    {names.length > 2 && <button type="button" className="admin-link" aria-expanded={expanded} onClick={() => setExpanded(!expanded)}>{expanded ? '收合' : `另有 ${names.length - 2} ${unit}`}</button>}
  </div>
}

function AdminForm({ kind, initial, options, onClose, onSave }) {
  const isCoach = kind === 'coach'
  const label = isCoach ? '教練' : '課程'
  const [form, setForm] = useState(initial)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const lock = useRef(false)
  const dialog = useRef(null)
  const closeButton = useRef(null)

  useEffect(() => {
    const node = dialog.current
    const previousFocus = document.activeElement
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    node.showModal()
    return () => {
      node.close()
      document.body.style.overflow = previousOverflow
      previousFocus?.focus()
    }
  }, [])

  function field(key, title, props = {}) {
    return <label className="admin-field" key={key}>{title}<input value={form[key] ?? ''} onChange={event => setForm({ ...form, [key]: event.target.value })} {...props} /></label>
  }

  async function submit(event) {
    event.preventDefault()
    if (lock.current) return
    lock.current = true
    setBusy(true)
    setError('')
    let saved = false
    try {
      const body = isCoach
        ? Object.fromEntries(['coachno', 'name', 'gender', 'phone', 'email'].map(key => [key, form[key].trim()]))
        : { coursename: form.coursename.trim(), coursetype: form.coursetype.trim(), description: form.description.trim(), price: Number(form.price) }
      if (isCoach) {
        if (!body.coachno || !body.name) throw new Error('請填寫教練編號與姓名。')
        body.specialty = options.filter(item => form.selected.includes(item.courseid)).map(item => item.coursename).join('、') || null
        if ((body.specialty?.length ?? 0) > 200) throw new Error('所選課程名稱合計超過專長欄位的 200 字限制。')
        if (!form.id && !body.phone) throw new Error('請填寫電話，將作為初始登入密碼。')
      } else {
        if (!body.coursename || !body.coursetype) throw new Error('請填寫課程名稱與類型。')
        if (!/^\d+(\.\d{1,2})?$/.test(String(form.price)) || !Number.isFinite(body.price) || body.price < 0 || body.price > 99999999.99) throw new Error('價格必須介於 0 至 99999999.99，最多兩位小數。')
      }
      const base = isCoach ? '/api/admin/coaches' : '/api/admin/courses'
      const result = await adminRequest(form.id ? `${base}/${form.id}` : base, form.id ? 'PUT' : 'POST', body)
      const id = result?.[isCoach ? 'coachid' : 'courseid']
      if (!Number.isInteger(id)) throw new Error('儲存回應缺少有效 ID，請關閉表單並重新讀取列表確認，避免重複新增。')
      saved = true
      // 基本資料成功後立刻記住 ID，部分失敗重試時使用 PUT。
      setForm(current => ({ ...current, id }))
	  if (result.status !== form.status) await adminRequest(`${base}/${id}/status`, 'PATCH', { status: form.status })
	  if (isCoach) await adminRequest(`/api/relation/coaches/${id}/courses`, 'PUT', { courseids: form.selected })
      else await saveCourseCoaches(id, form.selected, options)
      await onSave()
      onClose()
    } catch (failure) {
      setError(`${saved ? '基本資料已儲存，後續設定或重新讀取未全部完成；請確認後重試。' : ''}${failure.message}`)
    } finally {
      lock.current = false
      setBusy(false)
      closeButton.current?.focus()
    }
  }

  return <dialog ref={dialog} className="admin-dialog" aria-labelledby="admin-form-title" onCancel={event => { event.preventDefault(); if (!lock.current) onClose() }}>
    <form onSubmit={submit}>
      <header><h2 id="admin-form-title">{form.id ? '編輯' : '新增'}{label}</h2><button ref={closeButton} type="button" aria-label="關閉" disabled={busy} onClick={onClose}>×</button></header>
      <fieldset disabled={busy} className="admin-form-body">
        {isCoach ? <>
          {field('coachno', '教練編號', { required: true, maxLength: 20, placeholder: '必填' })}
          {field('name', '姓名', { required: true, maxLength: 50, placeholder: '必填' })}
          {field('gender', '性別', { required: true, maxLength: 10, placeholder: '必填' })}
          {field('phone', '電話', { required: true, type: 'tel', maxLength: 20, placeholder: '必填' })}
          {field('email', '電子郵件', { required: true, type: 'email', maxLength: 100, placeholder: '必填' })}
        </> : <>
          {field('coursename', '課程名稱', { required: true, maxLength: 100 })}
          <label className="admin-field">類型<select value={form.coursetype} onChange={event => setForm({ ...form, coursetype: event.target.value })}>
            {[...new Set(['重量訓練', '伸展放鬆', '懸吊訓練', form.coursetype])].filter(Boolean).map(type => <option key={type}>{type}</option>)}
          </select></label>
          <label className="admin-field">課程說明<textarea rows="3" maxLength="500" value={form.description} onChange={event => setForm({ ...form, description: event.target.value })} /></label>
          {field('durationmin', '時長（分鐘，後端設定）', { readOnly: true })}
          {field('price', '價格', { required: true, type: 'number', min: 0, max: 99999999.99, step: '0.01' })}
        </>}
        <fieldset className="admin-options"><legend>{isCoach ? '專長（可選多門課程）' : '授課教練（可選多位）'}</legend>
          {!options.length && <p>目前沒有{isCoach ? '課程，請先新增課程。' : '教練。'}</p>}
          <div>{options.map(item => {
            const id = item[isCoach ? 'courseid' : 'coachid']
            return <label key={id}><input type="checkbox" checked={form.selected.includes(id)} onChange={event => setForm({ ...form, selected: event.target.checked ? [...form.selected, id] : form.selected.filter(value => value !== id) })} />{item[isCoach ? 'coursename' : 'name']}</label>
          })}</div>
        </fieldset>
        {form.id && <label className="admin-field">狀態<select value={form.status} onChange={event => setForm({ ...form, status: event.target.value })}><option value="active">{isCoach ? '在職' : '上架'}</option><option value="inactive">{isCoach ? '離職' : '下架'}</option></select></label>}
      </fieldset>
      {error && <p className="admin-error" role="alert">{error}</p>}
      <footer><button type="button" disabled={busy} onClick={onClose}>取消</button><button className="admin-primary" disabled={busy} type="submit">{busy ? '儲存中…' : '儲存'}</button></footer>
    </form>
  </dialog>
}

export default function AdminManagement({ kind }) {
  const isCoach = kind === 'coach'
  const label = isCoach ? '教練' : '課程'
  const [data, setData] = useState({ coaches: [], courses: [], relations: {} })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [keyword, setKeyword] = useState('')
  const [form, setForm] = useState(null)
  const [revision, setRevision] = useState(0)

  useEffect(() => {
    const controller = new AbortController()
    loadAdminData(controller.signal).then(result => {
      setData(result)
      setLoading(false)
    }).catch(failure => {
      if (controller.signal.aborted) return
      setError(failure.message)
      setLoading(false)
    })
    return () => controller.abort()
  }, [revision])

  async function refresh() {
    const result = await loadAdminData()
    setData(result)
    setError('')
    setNotice('儲存成功，列表與授課關聯已更新。')
  }

  function open(item) {
    setNotice('')
    const id = item?.[isCoach ? 'coachid' : 'courseid']
    setForm(isCoach ? {
      id, coachno: item?.coachno ?? '', name: item?.name ?? '',
      gender: item?.gender ?? '', phone: item?.phone ?? '', email: item?.email ?? '', status: item?.status ?? 'active', selected: [...(data.relations[id] ?? [])],
    } : {
      id, coursename: item?.coursename ?? '', coursetype: item?.coursetype ?? '重量訓練', description: item?.description ?? '', durationmin: item?.durationmin ?? 60,
      price: item?.price ?? '', status: item?.status ?? 'active', selected: data.coaches.filter(coach => data.relations[coach.coachid]?.includes(id)).map(coach => coach.coachid),
    })
  }

  function namesFor(item) {
    return isCoach
      ? data.courses.filter(course => data.relations[item.coachid]?.includes(course.courseid)).map(course => course.coursename)
      : data.coaches.filter(coach => data.relations[coach.coachid]?.includes(item.courseid)).map(coach => coach.name)
  }

  const rows = (isCoach ? data.coaches : data.courses).filter(item => [...Object.values(item), ...namesFor(item), item.status === 'active' ? (isCoach ? '在職 啟用' : '上架') : (isCoach ? '離職 停用' : '下架')].join(' ').toLowerCase().includes(keyword.trim().toLowerCase()))
  const headers = isCoach ? ['教練ID', '教練編號', '姓名', '性別', '電話', '電子郵件', '可授課程', '狀態', '操作'] : ['課程編號', '課程名稱', '類型', '說明', '時長', '價格', '授課教練', '狀態', '操作']

  return <section className="admin-management" aria-busy={loading}>
    <div className="admin-toolbar"><h1>{label}管理</h1><div><input aria-label={`搜尋${label}`} placeholder="輸入欲查詢的關鍵字" value={keyword} onChange={event => setKeyword(event.target.value)} /><button className="admin-primary" disabled={loading || Boolean(error)} onClick={() => open(null)}>＋ 新增{label}</button></div></div>
    {error && <p className="admin-error" role="alert">{error} <button disabled={loading} onClick={() => { setError(''); setLoading(true); setRevision(value => value + 1) }}>重新讀取</button></p>}
    {notice && <p role="status" className="admin-success">{notice}</p>}
    <div className="admin-table-wrap"><table><thead><tr>{headers.map(header => <th key={header} scope="col">{header}</th>)}</tr></thead><tbody>
      {loading ? <tr><td colSpan="9">資料讀取中…</td></tr> : rows.length === 0 ? <tr><td colSpan="9">{keyword ? `找不到符合的${label}。` : `目前沒有${label}。`}</td></tr> : rows.map(item => {
        const id = item[isCoach ? 'coachid' : 'courseid']
        const cells = isCoach ? [id, item.coachno, item.name, item.gender, item.phone, item.email] : [id, item.coursename, item.coursetype, item.description, `${item.durationmin} 分鐘`, Number.isFinite(Number(item.price)) && item.price != null ? `NT$ ${Number(item.price).toLocaleString('zh-TW', { maximumFractionDigits: 2 })}` : '未填寫']
        return <tr key={id}>{cells.map((value, index) => <td key={index}>{value ?? '未填寫'}</td>)}<td><RelationTags names={namesFor(item)} unit={isCoach ? '項' : '位'} /></td><td><span className={`admin-status ${item.status === 'active' ? 'admin-active' : 'admin-inactive'}`}>{item.status === 'active' ? (isCoach ? '在職' : '上架') : (isCoach ? '離職' : '下架')}</span></td><td><div className="admin-actions"><button disabled={Boolean(error)} onClick={() => open(item)}>編輯</button></div></td></tr>
      })}
    </tbody></table></div>
    {form && <AdminForm kind={kind} initial={form} options={isCoach ? data.courses : data.coaches} onClose={() => setForm(null)} onSave={refresh} />}
  </section>
}
