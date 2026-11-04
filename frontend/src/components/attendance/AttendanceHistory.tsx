import type {
    AttendanceHistory as AttendanceHistoryType
} from "../../types/Attendance";

interface AttendanceHistoryProps {
    history: AttendanceHistoryType[];
}

function getStatusLabel(status: string) {
    switch (status) {
        case "PRESENT": return "已出席";
        case "LEAVE": return "請假";
        case "ABSENT": return "未出席";
        case "PENDING": return "待確認";
        default: return status;
    }
}

function getStatusClass(status: string) {
    switch (status) {
        case "PRESENT": return "status-present";
        case "LEAVE": return "status-leave";
        case "ABSENT": return "status-absent";
        case "PENDING": return "status-pending";
        default: return "";
    }
}

export default function AttendanceHistory({ history }: AttendanceHistoryProps) {
    const latestHistory = history.slice(0, 3);

    return (
        <aside className="attendance-history-panel" aria-label="出席歷史紀錄">
            <div className="attendance-history-header">
                <h2>最近 {latestHistory.length} 筆紀錄</h2>
            </div>
            <p className="attendance-history-caption">僅顯示本方案最近 3 筆歷史紀錄。</p>
            <ol className="attendance-history-list">
                {latestHistory.length === 0 ? (
                    <li className="attendance-history-empty">尚無歷史紀錄</li>
                ) : latestHistory.map((item, index) => (
                    <HistoryItem key={`${item.date}-${index}`} item={item} />
                ))}
            </ol>
        </aside>
    );
}

function HistoryItem({ item }: { item: AttendanceHistoryType }) {
    return (
        <li className="attendance-history-item">
            <div className="attendance-history-item-top">
                <time dateTime={item.date}>{item.date}</time>
                <span className={`attendance-status-badge ${getStatusClass(item.status)}`}>
                    {getStatusLabel(item.status)}
                </span>
            </div>
            <p className="attendance-history-workout" title={item.workoutFocus || "未記錄訓練摘要"}>
                {item.workoutFocus || "未記錄訓練摘要"}
            </p>
        </li>
    );
}
