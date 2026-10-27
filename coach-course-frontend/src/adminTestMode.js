// 明確網址開關；Vite 正式建置的 DEV 為 false，無法啟用。
export const adminTestMode = import.meta.env.DEV
  && new URLSearchParams(window.location.search).get('adminTest') === '1'
