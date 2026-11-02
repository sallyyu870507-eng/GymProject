export const FOLLOWUP_CONTENT_SHORTCUTS = [
  { label: "未接聽", text: "已致電，會員未接聽，待再次聯繫。" },
  { label: "稍後聯繫", text: "會員目前不方便，待另約時間聯繫。" },
  { label: "提醒上課", text: "已提醒會員安排後續上課時間。" },
  { label: "說明續約", text: "已說明續約方案，待會員考慮。" },
  { label: "近期較忙", text: "會員表示近期較忙，後續再追蹤上課安排。" },
];

function stripBackendWhitespace(value) {
  return value.replace(/^[\u0009-\u000D\u001C-\u001F\u0020\u1680\u2000-\u2006\u2008-\u200A\u2028\u2029\u205F\u3000]+|[\u0009-\u000D\u001C-\u001F\u0020\u1680\u2000-\u2006\u2008-\u200A\u2028\u2029\u205F\u3000]+$/gu, "");
}

export function appendFollowupContentShortcut(current, sentence) {
  if (current.includes(sentence)) return current;
  const separator = current.length === 0 || current.endsWith("\n") ? "" : "\n";
  const next = `${current}${separator}${sentence}`;
  return stripBackendWhitespace(next).length <= 500 ? next : null;
}
