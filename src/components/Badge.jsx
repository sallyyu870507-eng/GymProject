// 一律「圖示 + 文字」，不只靠顏色
export default function Badge({ cls, children }) {
  return <span className={`badge ${cls}`}>{children}</span>;
}
