import type {
    AttendanceUpdateStatus
} from "../../types/Attendance";

import "./AttendanceStatusSelector.css";


interface AttendanceStatusSelectorProps {

    status:
        AttendanceUpdateStatus
        | "";

    onChange: (
        status: AttendanceUpdateStatus
    ) => void;

    disabled: boolean;
}


function PresentIcon() {

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
                x="4"
                y="5"
                width="16"
                height="16"
                rx="2"
            />

            <path d="M8 3v4" />
            <path d="M16 3v4" />
            <path d="M4 10h16" />
            <path d="M9 15h6" />
        </svg>
    );
}


function AbsentIcon() {

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


export default function AttendanceStatusSelector(
    {
        status,
        onChange,
        disabled
    }: AttendanceStatusSelectorProps
) {

    return (
        <div className="attendance-status-selector">

            {/* =========================
                PRESENT
            ========================= */}

            <button
                type="button"
                className={
                    `attendance-status-option
                    attendance-status-option-present
                    ${
                        status === "PRESENT"
                            ? "attendance-status-option-selected"
                            : ""
                    }`
                }
                onClick={
                    () =>
                        onChange("PRESENT")
                }
                disabled={disabled}
                aria-pressed={
                    status === "PRESENT"
                }
            >

                <span className="attendance-status-option-icon">
                    <PresentIcon />
                </span>


                <span className="attendance-status-option-text">

                    <strong>
                        已出席
                    </strong>

                    <small>
                        扣除 1 堂
                    </small>

                </span>

            </button>


            {/* =========================
                LEAVE
            ========================= */}

            <button
                type="button"
                className={
                    `attendance-status-option
                    attendance-status-option-leave
                    ${
                        status === "LEAVE"
                            ? "attendance-status-option-selected"
                            : ""
                    }`
                }
                onClick={
                    () =>
                        onChange("LEAVE")
                }
                disabled={disabled}
                aria-pressed={
                    status === "LEAVE"
                }
            >

                <span className="attendance-status-option-icon">
                    <LeaveIcon />
                </span>


                <span className="attendance-status-option-text">

                    <strong>
                        請假
                    </strong>

                    <small>
                        不扣堂
                    </small>

                </span>

            </button>


            {/* =========================
                ABSENT
            ========================= */}

            <button
                type="button"
                className={
                    `attendance-status-option
                    attendance-status-option-absent
                    ${
                        status === "ABSENT"
                            ? "attendance-status-option-selected"
                            : ""
                    }`
                }
                onClick={
                    () =>
                        onChange("ABSENT")
                }
                disabled={disabled}
                aria-pressed={
                    status === "ABSENT"
                }
            >

                <span className="attendance-status-option-icon">
                    <AbsentIcon />
                </span>


                <span className="attendance-status-option-text">

                    <strong>
                        未出席
                    </strong>

                    <small>
                        不扣堂
                    </small>

                </span>

            </button>

        </div>
    );
}