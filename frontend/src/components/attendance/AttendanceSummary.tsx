import type {
    AttendanceSummary as AttendanceSummaryType
} from "../../types/Attendance";


interface AttendanceSummaryProps {
    summary: AttendanceSummaryType;
}


/* =========================================================
   Icons

   使用 currentColor，
   所以顏色會直接沿用 summary-icon-* 的 CSS。
   未來換 Theme 不需要修改 SVG。
   ========================================================= */

function CalendarIcon() {
    return (
        <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
        >
            <rect
                x="3"
                y="5"
                width="18"
                height="16"
                rx="2"
            />

            <path d="M16 3v4" />
            <path d="M8 3v4" />
            <path d="M3 10h18" />
        </svg>
    );
}


function CheckCircleIcon() {
    return (
        <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
        >
            <circle
                cx="12"
                cy="12"
                r="9"
            />

            <path d="m8 12 2.5 2.5L16 9" />
        </svg>
    );
}


function ClockIcon() {
    return (
        <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
        >
            <circle
                cx="12"
                cy="12"
                r="9"
            />

            <path d="M12 7v5l3 2" />
        </svg>
    );
}


function LeaveIcon() {
    return (
        <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
        >
            <rect
                x="3"
                y="5"
                width="18"
                height="16"
                rx="2"
            />

            <path d="M16 3v4" />
            <path d="M8 3v4" />
            <path d="M3 10h18" />

            <path d="M9 15h6" />
        </svg>
    );
}


function UserXIcon() {
    return (
        <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
        >
            <circle
                cx="9"
                cy="8"
                r="3"
            />

            <path d="M3 20c0-3 2.5-5 6-5" />

            <path d="m16 14 5 5" />
            <path d="m21 14-5 5" />
        </svg>
    );
}


function XCircleIcon() {
    return (
        <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
        >
            <circle
                cx="12"
                cy="12"
                r="9"
            />

            <path d="m9 9 6 6" />
            <path d="m15 9-6 6" />
        </svg>
    );
}


export default function AttendanceSummary(
    { summary }: AttendanceSummaryProps
) {

    return (
        <section className="attendance-summary">

            {/* =========================
                今日課程
            ========================= */}

            <article className="summary-item">

                <div className="summary-icon summary-icon-primary">
                    <CalendarIcon />
                </div>

                <div className="summary-content">

                    <span className="summary-label">
                        今日課程
                    </span>

                    <div className="summary-value-row">

                        <strong>
                            {summary.totalClasses}
                        </strong>

                        <span>
                            堂
                        </span>

                    </div>

                </div>

            </article>


            {/* =========================
                已出席
            ========================= */}

            <article className="summary-item">

                <div className="summary-icon summary-icon-success">
                    <CheckCircleIcon />
                </div>

                <div className="summary-content">

                    <span className="summary-label">
                        已出席
                    </span>

                    <div className="summary-value-row">

                        <strong>
                            {summary.present}
                        </strong>

                        <span>
                            堂
                        </span>

                    </div>

                </div>

            </article>


            {/* =========================
                待確認
            ========================= */}

            <article className="summary-item">

                <div className="summary-icon summary-icon-warning">
                    <ClockIcon />
                </div>

                <div className="summary-content">

                    <span className="summary-label">
                        待確認
                    </span>

                    <div className="summary-value-row">

                        <strong>
                            {summary.pending}
                        </strong>

                        <span>
                            堂
                        </span>

                    </div>

                </div>

            </article>


            {/* =========================
                請假
            ========================= */}

            <article className="summary-item">

                <div className="summary-icon summary-icon-leave">
                    <LeaveIcon />
                </div>

                <div className="summary-content">

                    <span className="summary-label">
                        請假
                    </span>

                    <div className="summary-value-row">

                        <strong>
                            {summary.leave}
                        </strong>

                        <span>
                            堂
                        </span>

                    </div>

                </div>

            </article>


            {/* =========================
                缺席
            ========================= */}

            <article className="summary-item">

                <div className="summary-icon summary-icon-danger">
                    <UserXIcon />
                </div>

                <div className="summary-content">

                    <span className="summary-label">
                        缺席
                    </span>

                    <div className="summary-value-row">

                        <strong>
                            {summary.absent}
                        </strong>

                        <span>
                            堂
                        </span>

                    </div>

                </div>

            </article>


            {/* =========================
                已取消
            ========================= */}

            <article className="summary-item">

                <div className="summary-icon summary-icon-neutral">
                    <XCircleIcon />
                </div>

                <div className="summary-content">

                    <span className="summary-label">
                        已取消
                    </span>

                    <div className="summary-value-row">

                        <strong>
                            {summary.cancelled}
                        </strong>

                        <span>
                            堂
                        </span>

                    </div>

                </div>

            </article>

        </section>
    );
}