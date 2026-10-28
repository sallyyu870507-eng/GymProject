// 僅限 Vite 開發環境；正式建置無法啟用。
const params = new URLSearchParams(window.location.search)
export const adminTestMode = import.meta.env.DEV
  && params.get('adminTest') === '1'
// 同時指定兩個參數時，管理員模式優先。
export const studentTestMode = import.meta.env.DEV
  && !adminTestMode && params.get('studentTest') === '1'
export const testRole = adminTestMode ? 'admin' : studentTestMode ? 'member' : null
