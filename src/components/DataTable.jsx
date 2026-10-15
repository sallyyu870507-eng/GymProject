// 通用表格：columns = [{ label, key?, render?(row) }]（React 會自動跳脫文字，不用自己處理 XSS）
export default function DataTable({ columns, rows }) {
  if (!rows.length) return <div className="state">目前沒有資料</div>;
  return (
    <table>
      <thead><tr>{columns.map(c => <th key={c.label}>{c.label}</th>)}</tr></thead>
      <tbody>
        {rows.map((r, i) => (
          <tr key={i}>{columns.map(c => <td key={c.label}>{c.render ? c.render(r) : r[c.key]}</td>)}</tr>
        ))}
      </tbody>
    </table>
  );
}
