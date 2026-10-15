const pad = n => String(n).padStart(2, "0");

// 後端 LocalDate / LocalTime 可能是字串，也可能是陣列（[2026,10,8]、[9,0]），統一轉成字串
export const isoDate = v => Array.isArray(v) ? `${v[0]}-${pad(v[1])}-${pad(v[2])}` : String(v ?? "");
export const hhmm = v => Array.isArray(v) ? `${pad(v[0])}:${pad(v[1])}` : String(v ?? "").slice(0, 5);

export const today = () => new Date().toLocaleDateString("sv-SE");   // YYYY-MM-DD（本地時區）
export const addDays = (d, n) => {
  const x = new Date(d + "T00:00:00");
  x.setDate(x.getDate() + n);
  return x.toLocaleDateString("sv-SE");
};
