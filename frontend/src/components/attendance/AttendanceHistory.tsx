import { useEffect, useRef, useState } from "react";

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
    const [isOpen, setIsOpen] = useState(false);
    const triggerRef = useRef<HTMLButtonElement>(null);
    const closeRef = useRef<HTMLButtonElement>(null);
    const drawerRef = useRef<HTMLElement>(null);
    const latestHistory = history.slice(0, 3);

    function closeDrawer() {
        setIsOpen(false);
        window.requestAnimationFrame(() => triggerRef.current?.focus());
    }

    useEffect(() => {
        if (!isOpen) return;

        const previousOverflow = document.body.style.overflow;
        document.body.style.overflow = "hidden";
        closeRef.current?.focus();

        function handleKeyDown(event: KeyboardEvent) {
            if (event.key === "Escape") {
                event.preventDefault();
                closeDrawer();
                return;
            }
            if (event.key !== "Tab") return;

            const focusable = drawerRef.current?.querySelectorAll<HTMLElement>(
                'button:not(:disabled), [href], input:not(:disabled), select:not(:disabled), textarea:not(:disabled), [tabindex]:not([tabindex="-1"])'
            );
            if (!focusable?.length) {
                event.preventDefault();
                drawerRef.current?.focus();
                return;
            }
            const first = focusable[0];
            const last = focusable[focusable.length - 1];
            if (event.shiftKey && document.activeElement === first) {
                event.preventDefault();
                last.focus();
            } else if (!event.shiftKey && document.activeElement === last) {
                event.preventDefault();
                first.focus();
            }
        }

        document.addEventListener("keydown", handleKeyDown);
        return () => {
            document.body.style.overflow = previousOverflow;
            document.removeEventListener("keydown", handleKeyDown);
        };
    }, [isOpen]);

    return (
        <>
            <aside className="attendance-history-panel" aria-label="最近出席紀錄">
                <div className="attendance-history-header">
                    <h2>歷史紀錄</h2>
                    <button
                        ref={triggerRef}
                        type="button"
                        className="attendance-history-more"
                        aria-haspopup="dialog"
                        aria-expanded={isOpen}
                        aria-controls="attendance-history-drawer"
                        onClick={() => setIsOpen(true)}
                    >
                        查看可用紀錄
                    </button>
                </div>
                <ol className="attendance-history-list">
                    {latestHistory.length === 0 ? (
                        <li className="attendance-history-empty">尚無歷史紀錄</li>
                    ) : latestHistory.map((item, index) => (
                        <HistoryItem key={`${item.date}-${index}`} item={item} />
                    ))}
                </ol>
            </aside>

            {isOpen && (
                <div
                    className="history-drawer-backdrop"
                    onClick={(event) => {
                        if (event.target === event.currentTarget) closeDrawer();
                    }}
                >
                    <aside
                        id="attendance-history-drawer"
                        ref={drawerRef}
                        className="history-drawer"
                        role="dialog"
                        aria-modal="true"
                        aria-labelledby="attendance-history-drawer-title"
                        tabIndex={-1}
                    >
                        <div className="history-drawer-header">
                            <h2 id="attendance-history-drawer-title">可取得的歷史紀錄</h2>
                            <button ref={closeRef} type="button" onClick={closeDrawer} aria-label="關閉歷史紀錄">關閉</button>
                        </div>
                        <p className="history-drawer-limit">目前出席詳情 API 僅提供同方案最近 5 筆紀錄；以下為全部可取得資料。</p>
                        {history.length === 0 ? (
                            <p className="attendance-history-empty">尚無歷史紀錄</p>
                        ) : (
                            <ol className="attendance-history-list attendance-history-drawer-list">
                                {history.map((item, index) => (
                                    <HistoryItem key={`${item.date}-${index}`} item={item} />
                                ))}
                            </ol>
                        )}
                    </aside>
                </div>
            )}
        </>
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
