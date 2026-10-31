/** Shared notification state, kept independent of React for JS and TS callers. */
export function createNotificationStore() {
  let sequence = 0
  let snapshot = { toasts: [], confirmation: null }
  const listeners = new Set()
  const pending = []
  const emit = () => { for (const listener of listeners) listener() }
  const update = changes => { snapshot = { ...snapshot, ...changes }; emit() }
  function removeToast(id) {
    update({ toasts: snapshot.toasts.filter(toast => toast.id !== id) })
  }
  function settle(id, accepted) {
    const index = pending.findIndex(item => item.id === id)
    if (index === -1) return
    const [item] = pending.splice(index, 1)
    item.cleanup()
    update({ confirmation: pending[0] ?? null })
    item.resolve(Boolean(accepted))
  }
  return {
    subscribe(listener) { listeners.add(listener); return () => listeners.delete(listener) },
    getSnapshot() { return snapshot },
    removeToast,
    /** @param {unknown} message @param {{type?: 'success'|'error'|'info', duration?: number}} [options] */
    toast(message, { type = 'info', duration = type === 'error' ? 10000 : 5000 } = {}) {
      const id = ++sequence
      update({ toasts: [...snapshot.toasts, { id, message: String(message ?? ''), type, duration }] })
      return id
    },
    /** @param {unknown} message @param {{title?: string, confirmLabel?: string, cancelLabel?: string, danger?: boolean, signal?: AbortSignal}} [options] @returns {Promise<boolean>} */
    confirm(message, { title = '請確認操作', confirmLabel = '確定', cancelLabel = '取消', danger = false, signal } = {}) {
      if (signal?.aborted) return Promise.resolve(false)
      return new Promise(resolve => {
        const id = ++sequence
        const abort = () => settle(id, false)
        const item = { id, message: String(message ?? ''), title, confirmLabel, cancelLabel, danger, resolve,
          cleanup: () => signal?.removeEventListener('abort', abort) }
        pending.push(item)
        signal?.addEventListener('abort', abort, { once: true })
        if (pending.length === 1) update({ confirmation: item })
      })
    },
    answer: settle,
    cancelAll() {
      const items = pending.splice(0)
      update({ confirmation: null })
      for (const item of items) { item.cleanup(); item.resolve(false) }
    },
  }
}

export const notificationStore = createNotificationStore()
export const showToast = (message, options = {}) => notificationStore.toast(message, options)
export const confirmDialog = (message, options = {}) => notificationStore.confirm(message, options)
