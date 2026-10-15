const KEY = "gym-theme";

export function initTheme() {
  let t = null;
  try { t = localStorage.getItem(KEY); } catch {}
  document.documentElement.dataset.theme = t || "dark";   // 預設深色
}

export function toggleTheme() {
  const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
  document.documentElement.dataset.theme = next;
  try { localStorage.setItem(KEY, next); } catch {}
}
