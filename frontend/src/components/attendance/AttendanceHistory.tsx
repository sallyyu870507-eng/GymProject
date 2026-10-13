import {
    useState
} from "react";

import type {
    AttendanceHistory as AttendanceHistoryType
} from "../../types/Attendance";


interface AttendanceHistoryProps {
    history: AttendanceHistoryType[];
}


function getStatusLabel(
    status: string
) {

    switch (status) {

        case "PRESENT":
            return "已出席";

        case "LEAVE":
            return "請假";

        case "ABSENT":
            return "未出席";

        case "PENDING":
            return "待確認";

        default:
            return status;
    }
}


function getStatusClass(
    status: string
) {

    switch (status) {

        case "PRESENT":
            return "status-present";

        case "LEAVE":
            return "status-leave";

        case "ABSENT":
            return "status-absent";

        case "PENDING":
            return "status-pending";

        default:
            return "";
    }
}


export default function AttendanceHistory(
    {
        history
    }: AttendanceHistoryProps
) {

    const [
        showAll,
        setShowAll
    ] =
        useState(false);


    const visibleHistory =
        showAll
            ? history
            : history.slice(0, 3);


    return (
        <aside className="attendance-history-panel">

            <div className="attendance-history-header">

                <h2>
                    歷史紀錄
                </h2>


                {
                    history.length > 3
                    && (
                        <button
                            type="button"
                            className="attendance-history-more"
                            onClick={
                                () =>
                                    setShowAll(
                                        current =>
                                            !current
                                    )
                            }
                        >
                            {
                                showAll
                                    ? "收合"
                                    : "查看全部"
                            }
                        </button>
                    )
                }

            </div>


            {
                history.length === 0
                    ? (
                        <div className="attendance-history-empty">
                            尚無歷史紀錄
                        </div>
                    )
                    : (
                        <div className="attendance-history-list">

                            {
                                visibleHistory.map(
                                    (
                                        item,
                                        index
                                    ) => (
                                        <article
                                            key={
                                                `${item.date}-${index}`
                                            }
                                            className="attendance-history-item"
                                        >

                                            <div className="attendance-history-item-top">

                                                <strong>
                                                    {item.date}
                                                </strong>


                                                <span
                                                    className={
                                                        `attendance-status-badge
                                                        ${getStatusClass(
                                                            item.status
                                                        )}`
                                                    }
                                                >
                                                    {
                                                        getStatusLabel(
                                                            item.status
                                                        )
                                                    }
                                                </span>

                                            </div>


                                            <div className="attendance-history-content">

                                                <p className="attendance-history-workout">

                                                    <span>
                                                        訓練
                                                    </span>

                                                    {
                                                        item.workoutFocus
                                                        ?? "未記錄"
                                                    }

                                                </p>


                                                {
                                                    item.note
                                                    && (
                                                        <p className="attendance-history-note">
                                                            {item.note}
                                                        </p>
                                                    )
                                                }

                                            </div>

                                        </article>
                                    )
                                )
                            }

                        </div>
                    )
            }

        </aside>
    );
}