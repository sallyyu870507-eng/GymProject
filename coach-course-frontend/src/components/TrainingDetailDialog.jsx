import { useEffect, useId, useRef, useState } from 'react'
import { coachImage, courseImages, fetchJson, loadRelated } from './detailApi'
import './DetailLinks.css'

const courseAudiences = {
  初階重訓: '沒有重訓經驗，或希望建立正確動作與訓練基礎的學員。',
  中階重訓: '已有重訓基礎，希望進一步提升肌力與動作穩定度的學員。',
  高階重訓: '具備規律訓練經驗，希望挑戰更高強度與突破訓練瓶頸的學員。',
  筋膜放鬆: '運動後感到肌肉緊繃，或希望透過伸展放鬆身體的學員。',
  TRX: '希望運用自身體重，訓練全身肌力、核心與平衡能力的學員。',
}

export default function TrainingDetailDialog({ initialKind, initialId, imageSrc, onClose }) {
  const dialogRef = useRef(null)
  const titleRef = useRef(null)
  const titleId = useId()
  const [history, setHistory] = useState([
    { kind: initialKind, id: initialId, imageSrc },
  ])
  const current = history[history.length - 1]
  const viewKey = `${current.kind}:${current.id}`
  const [state, setState] = useState({ key: '', data: null, error: '' })
  const [related, setRelated] = useState({ key: '', items: [], error: '' })
  const loading = state.key !== viewKey
  const data = loading ? null : state.data
  const relatedLoading = related.key !== viewKey
  const isCoach = current.kind === 'coach'

  useEffect(() => {
    const dialog = dialogRef.current
    const originalOverflow = document.body.style.overflow
    const previousFocus = document.activeElement
    dialog.showModal()
    document.body.style.overflow = 'hidden'
    return () => {
      dialog.close()
      document.body.style.overflow = originalOverflow
      if (previousFocus instanceof HTMLElement && previousFocus.isConnected) {
        previousFocus.focus()
      }
    }
  }, [])

  useEffect(() => {
    const controller = new AbortController()
    const signal = controller.signal
    dialogRef.current.scrollTop = 0
    titleRef.current?.focus()

    async function load() {
      try {
        const data = await fetchJson(
          `/api/student/${current.kind === 'coach' ? 'coaches' : 'courses'}/${current.id}`,
          signal,
        )
        if (signal.aborted) return
        setState({ key: viewKey, data, error: '' })

        try {
          const items = await loadRelated(current.kind, current.id, signal)
          if (!signal.aborted) setRelated({ key: viewKey, items, error: '' })
        } catch (error) {
          if (signal.aborted) return
          setRelated({
            key: viewKey,
            items: [],
            error: `授課關聯暫時無法載入：${error.message}`,
          })
        }
      } catch (error) {
        if (!signal.aborted) setState({ key: viewKey, data: null, error: error.message })
      }
    }
    load()
    return () => controller.abort()
  }, [current.kind, current.id, viewKey])

  function returnOrClose() {
    if (history.length > 1) setHistory((items) => items.slice(0, -1))
    else onClose()
  }

  function openRelated(item) {
    const kind = isCoach ? 'course' : 'coach'
    const id = isCoach ? item.courseid : item.coachid
    const image = isCoach ? courseImages[item.coursename] : coachImage(item.name)
    setHistory((items) => [...items, { kind, id, imageSrc: image }])
  }

  function handleBackdropClick(event) {
    if (event.target !== event.currentTarget) return
    const rect = event.currentTarget.getBoundingClientRect()
    if (event.clientX < rect.left || event.clientX > rect.right ||
        event.clientY < rect.top || event.clientY > rect.bottom) returnOrClose()
  }

  const photo = current.imageSrc || (isCoach
    ? coachImage(data?.name)
    : courseImages[data?.coursename] || '/images/banner.jpg')

  const links = (
    <section className="cc-related-section" aria-label={isCoach ? '可授課程' : '授課教練'}>
      <h3>{isCoach ? '可授課程' : '授課教練'}</h3>
      {relatedLoading ? (
        <p className="cc-description" role="status">授課資料讀取中……</p>
      ) : related.error ? (
        <p className="cc-error" role="alert">{related.error}</p>
      ) : related.items.length === 0 ? (
        <p className="cc-description">
          {isCoach ? '目前沒有上架中的可授課程。' : '目前沒有可顯示的授課教練。'}
        </p>
      ) : (
        <div className="cc-related-links">
          {related.items.map((item) => (
            <button
              type="button"
              className="cc-related-link"
              key={isCoach ? item.courseid : item.coachid}
              onClick={() => openRelated(item)}
            >
              {isCoach ? item.coursename : `${item.name} 教練`}
              <span aria-hidden="true">↗</span>
            </button>
          ))}
        </div>
      )}
    </section>
  )

  return (
    <dialog
      ref={dialogRef}
      className="cc-detail-dialog cc-linked-dialog"
      aria-labelledby={titleId}
      onClick={handleBackdropClick}
      onCancel={(event) => { event.preventDefault(); returnOrClose() }}
    >
      <button type="button" className="cc-detail-close" aria-label="關閉目前介紹" onClick={returnOrClose}>×</button>

      {!isCoach && <img className="cc-detail-image" src={photo} alt="課程訓練示意圖" />}

      <div className="cc-detail-content">
        <h2 id={titleId} ref={titleRef} tabIndex={-1}>
          {data ? (isCoach ? `${data.name} 教練` : data.coursename)
            : isCoach ? '教練詳細介紹' : '課程詳細介紹'}
        </h2>
        {loading && <p role="status">資料讀取中……</p>}
        {!loading && state.error && <p className="cc-error" role="alert">{state.error}</p>}

        {data && (isCoach ? (
          <div className="cc-coach-detail-profile">
            {photo && <img className="cc-coach-detail-photo" src={photo} alt={`${data.name}教練`} />}
            <div className="cc-coach-detail-info">
              {links}
              <section className="cc-coach-contact-section">
                <h3 className="cc-coach-contact-title">聯絡資訊</h3>
                <dl>
                  <dt>性別</dt><dd>{data.gender || '尚未提供'}</dd>
                  <dt>電話</dt><dd>{data.phone || '尚未提供'}</dd>
                  <dt>Email</dt><dd>{data.email || '尚未提供'}</dd>
                </dl>
              </section>
            </div>
          </div>
        ) : (
          <>
            <span className="cc-detail-type">{data.coursetype}</span>
            <h3>課程介紹</h3>
            <p className="cc-detail-description">{data.description || '目前尚未提供課程說明。'}</p>
            <h3>適合對象</h3>
            <p className="cc-detail-description">{courseAudiences[data.coursename] || '希望透過專業指導培養運動習慣的學員。'}</p>
            {links}
            <div className="cc-detail-duration">每堂 {data.durationmin} 分鐘</div>
          </>
        ))}

        <div className={`cc-detail-footer ${isCoach ? 'cc-coach-detail-footer' : ''}`}>
          {data && !isCoach && (
            <div className="cc-course-price">
              <span className="cc-currency">NT$</span>
              {Number(data.price).toLocaleString('zh-TW')}
              <span className="cc-price-unit">/單堂</span>
            </div>
          )}
          <button type="button" className="cc-detail-return" onClick={returnOrClose}>
            {history.length > 1 ? '返回上一個介紹' : isCoach ? '關閉介紹' : '返回課程列表'}
          </button>
        </div>
      </div>
    </dialog>
  )
}
