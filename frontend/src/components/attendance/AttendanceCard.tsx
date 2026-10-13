import type {
    AttendanceCard as AttendanceCardType
} from "../../types/Attendance";


interface AttendanceCardProps {
    card: AttendanceCardType;

    // 這張卡目前是否被選中
    selected: boolean;

    // 點擊正常卡片時，把 bookingId 傳回 AttendancePage
    onSelect: (
        bookingId: number
    ) => void;
}


function formatTime(
    time: string
) {

    return time.length >= 5
        ? time.substring(0, 5)
        : time;
}


function getAttendanceStatusLabel(
    attendanceStatus: string,
    isCancelled: boolean
) {

    if (isCancelled) {
        return "已取消";
    }


    switch (attendanceStatus) {

        case "PRESENT":
            return "已出席";

        case "PENDING":
            return "待確認";

        case "LEAVE":
            return "請假";

        case "ABSENT":
            return "未出席";

        default:
            return attendanceStatus;
    }
}


function getAttendanceStatusClass(
    attendanceStatus: string,
    isCancelled: boolean
) {

    if (isCancelled) {
        return "status-cancelled";
    }


    switch (attendanceStatus) {

        case "PRESENT":
            return "status-present";

        case "PENDING":
            return "status-pending";

        case "LEAVE":
            return "status-leave";

        case "ABSENT":
            return "status-absent";

        default:
            return "";
    }
}


function getMemberInitial(
    memberName: string
) {

    const trimmedName =
        memberName.trim();


    if (!trimmedName) {
        return "會";
    }


    return trimmedName.charAt(0);
}


export default function AttendanceCard(
    {
        card,
        selected,
        onSelect
    }: AttendanceCardProps
) {

    const isCancelled =
        card.bookingStatus
            .toUpperCase()
        === "CANCELLED";


    const statusLabel =
        getAttendanceStatusLabel(
            card.attendanceStatus,
            isCancelled
        );


    const statusClass =
        getAttendanceStatusClass(
            card.attendanceStatus,
            isCancelled
        );


    return (
        <article
            className={
                `attendance-card
                ${
                    isCancelled
                        ? "attendance-card-cancelled"
                        : ""
                }
                ${
                    selected
                        ? "attendance-card-selected"
                        : ""
                }`
            }

            // CANCELLED → 完全沒有 click 行為
            // 正常卡 → 點擊後回報 bookingId
            onClick={
                isCancelled
                    ? undefined
                    : () =>
                        onSelect(
                            card.bookingId
                        )
            }
        >

            {/* =========================
                Time + Status
            ========================= */}

            <div className="attendance-card-top">

                <span className="attendance-card-time">

                    {formatTime(card.startTime)}

                    {" - "}

                    {formatTime(card.endTime)}

                </span>


                <span
                    className={
                        `attendance-status-badge
                        ${statusClass}`
                    }
                >
                    {statusLabel}
                </span>

            </div>


            {/* =========================
                Member
            ========================= */}

            <div className="attendance-card-member">

                <div className="attendance-member-avatar">

                    {
                        card.avatarUrl
                            ? (
                                <img
                                    src={card.avatarUrl}
                                    alt={card.memberName}
                                />
                            )
                            : (
                                getMemberInitial(
                                    card.memberName
                                )
                            )
                    }

                </div>


                <div className="attendance-member-info">

                    <h3>
                        {card.memberName}
                    </h3>

                    <p>
                        {card.courseName}
                    </p>

                </div>

            </div>


            {/* =========================
                Footer
            ========================= */}

            <div className="attendance-card-footer">

                <span className="attendance-session-label">
                    剩餘
                </span>


                <span className="attendance-session-count">

                    {card.remainingSessions}

                    <span>
                        堂
                    </span>

                </span>


                {
                    !isCancelled && (
                        <span className="attendance-card-arrow">
                            ›
                        </span>
                    )
                }

            </div>

        </article>
    );
}