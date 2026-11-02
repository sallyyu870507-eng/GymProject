import { useEffect, useRef, useState, useSyncExternalStore } from 'react'
import { createPortal } from 'react-dom'
import { notificationStore } from '../notifications.js'
import './Notifications.css'

function NoticeIcon({ type }) {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    {type === 'success' ? <><circle cx="12" cy="12" r="9" /><path d="m8 12 3 3 5-6" /></> :
      type === 'error' ? <><circle cx="12" cy="12" r="9" /><path d="m9 9 6 6m-6 0 6-6" /></> :
        <><circle cx="12" cy="12" r="9" /><path d="M12 11v5m0-9v.1" /></>}
  </svg>
}

function Toast({ toast }) {
  const [paused, setPaused] = useState(false)
  useEffect(() => {
    if (paused || toast.duration <= 0) return
    const timer = setTimeout(() => notificationStore.removeToast(toast.id), toast.duration)
    return () => clearTimeout(timer)
  }, [toast, paused])
  return <div className={`gym-toast gym-toast-${toast.type}`} role={toast.type === 'error' ? 'alert' : 'status'}
    onMouseEnter={() => setPaused(true)} onMouseLeave={() => setPaused(false)}
    onFocus={() => setPaused(true)} onBlur={event => { if (!event.currentTarget.contains(event.relatedTarget)) setPaused(false) }}>
    <span className="gym-toast-icon"><NoticeIcon type={toast.type} /></span>
    <div className="gym-toast-message">{toast.message}</div>
    <button type="button" className="gym-notice-close" aria-label="關閉通知" onClick={() => notificationStore.removeToast(toast.id)}>×</button>
  </div>
}

export default function NotificationHost() {
  const { toasts, confirmation } = useSyncExternalStore(notificationStore.subscribe, notificationStore.getSnapshot)
  const dialog = useRef(null)
  const cancelButton = useRef(null)
  const toastRegion = useRef(null)
  const [toastContainer, setToastContainer] = useState(document.body)
  useEffect(() => {
    const syncContainer = () => {
      const openDialogs = document.querySelectorAll('dialog[open]')
      setToastContainer(openDialogs[openDialogs.length - 1] ?? document.body)
    }
    const observer = new MutationObserver(syncContainer)
    observer.observe(document.body, { subtree: true, childList: true, attributes: true, attributeFilter: ['open'] })
    syncContainer()
    return () => observer.disconnect()
  }, [])
  useEffect(() => {
    const node = dialog.current
    if (confirmation) {
      if (!node.open) node.showModal()
      cancelButton.current?.focus()
    } else if (node.open) node.close()
  }, [confirmation?.id])
  useEffect(() => {
    const node = toastRegion.current
    if (node.showPopover) {
      // Top-layer notifications remain visible above existing form dialogs.
      if (toasts.length && !node.matches(':popover-open')) node.showPopover()
      else if (!toasts.length && node.matches(':popover-open')) node.hidePopover()
    }
  }, [toasts.length, confirmation?.id, toastContainer])
  useEffect(() => () => notificationStore.cancelAll(), [])
  const answer = accepted => { if (confirmation) notificationStore.answer(confirmation.id, accepted) }
  return <>
    {createPortal(<dialog ref={dialog} className="gym-confirm-dialog" aria-labelledby="gym-confirm-title" aria-describedby="gym-confirm-message"
      onCancel={event => { event.preventDefault(); answer(false) }}>
      {confirmation && <>
        <div className="gym-confirm-heading">
          <span className={`gym-confirm-icon${confirmation.danger ? ' gym-confirm-danger-icon' : ''}`}><NoticeIcon type="info" /></span>
          <button type="button" className="gym-notice-close" aria-label="關閉確認對話框" onClick={() => answer(false)}>×</button>
        </div>
        <h2 id="gym-confirm-title">{confirmation.title}</h2>
        <p id="gym-confirm-message">{confirmation.message}</p>
        <div className="gym-confirm-actions">
          <button ref={cancelButton} type="button" className="gym-confirm-cancel" onClick={() => answer(false)}>{confirmation.cancelLabel}</button>
          <button type="button" className={`gym-confirm-accept${confirmation.danger ? ' gym-confirm-danger' : ''}`} onClick={() => answer(true)}>{confirmation.confirmLabel}</button>
        </div>
      </>}
    </dialog>, document.body)}
    {createPortal(<div ref={toastRegion} className="gym-toast-region" popover="manual" aria-label="操作通知">
      {toasts.map(toast => <Toast key={toast.id} toast={toast} />)}
    </div>, toastContainer)}
  </>
}
