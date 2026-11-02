import { useRef, useState } from "react";

interface AttendanceHeaderProps {
    date: string;
    onDateChange: (date: string) => void;
}


function shiftDate(
    date: string,
    days: number
): string {

    const currentDate =
        new Date(`${date}T00:00:00`);

    currentDate.setDate(
        currentDate.getDate() + days
    );

    const year =
        currentDate.getFullYear();

    const month =
        String(
            currentDate.getMonth() + 1
        ).padStart(2, "0");

    const day =
        String(
            currentDate.getDate()
        ).padStart(2, "0");


    return `${year}-${month}-${day}`;
}


function formatDisplayDate(
    date: string
): string {

    const currentDate =
        new Date(`${date}T00:00:00`);


    return new Intl.DateTimeFormat(
        "zh-TW",
        {
            year: "numeric",
            month: "long",
            day: "numeric",
            weekday: "short"
        }
    ).format(currentDate);
}


function getToday(): string {
    const parts = new Intl.DateTimeFormat(
        "en-CA",
        {
            timeZone: "Asia/Taipei",
            year: "numeric",
            month: "2-digit",
            day: "2-digit"
        }
    ).formatToParts(new Date());

    const values = Object.fromEntries(
        parts.map(part => [part.type, part.value])
    );

    return `${values.year}-${values.month}-${values.day}`;
}


export default function AttendanceHeader(
    {
        date,
        onDateChange
    }: AttendanceHeaderProps
) {
    const dateInputRef = useRef<HTMLInputElement>(null);
    const [showNativeDateInput, setShowNativeDateInput] = useState(false);

    function openDatePicker() {
        const input = dateInputRef.current as (HTMLInputElement & { showPicker?: () => void }) | null;
        if (input?.showPicker) {
            try {
                input.showPicker();
                return;
            } catch {
                // Fall back to the visible native input below.
            }
        }

        setShowNativeDateInput(true);
        window.requestAnimationFrame(() => dateInputRef.current?.focus());
    }

    function handlePreviousDay() {

        onDateChange(
            shiftDate(date, -1)
        );
    }


    function handleNextDay() {

        onDateChange(
            shiftDate(date, 1)
        );
    }


    function handleToday() {

        onDateChange(
            getToday()
        );
    }


    return (
        <header className="attendance-page-header">

            <div className="attendance-page-heading">

                <h1>
                    今日出席管理
                </h1>

                <p>
                    管理每日課程出席狀況，
                    記錄學員訓練內容與身體數據
                </p>

            </div>


            <div className="attendance-date-control">

                <button
                    type="button"
                    className="attendance-date-arrow"
                    onClick={handlePreviousDay}
                    aria-label="前一天"
                >
                    ←
                </button>


                <div className={`attendance-date-picker${showNativeDateInput ? " has-native-fallback" : ""}`}>
                    {showNativeDateInput ? (
                        <input
                            ref={dateInputRef}
                            className="attendance-date-native-fallback"
                            type="date"
                            aria-label={`選擇日期，目前為 ${date}`}
                            value={date}
                            onChange={event => onDateChange(event.target.value)}
                        />
                    ) : (
                        <>
                            <button
                                type="button"
                                className="attendance-date-trigger"
                                onClick={openDatePicker}
                                aria-label={`選擇日期，目前為 ${date}`}
                            >
                                <span>{formatDisplayDate(date)}</span>
                                <svg viewBox="0 0 24 24" aria-hidden="true">
                                    <rect x="3.5" y="5" width="17" height="16" rx="2" fill="none" stroke="currentColor" strokeWidth="1.8" />
                                    <path d="M7.5 3v4M16.5 3v4M4 9.5h16" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
                                </svg>
                            </button>
                            <input
                                ref={dateInputRef}
                                className="attendance-date-native-hidden"
                                type="date"
                                tabIndex={-1}
                                aria-hidden="true"
                                value={date}
                                onChange={event => onDateChange(event.target.value)}
                            />
                        </>
                    )}
                </div>


                <button
                    type="button"
                    className="attendance-date-arrow"
                    onClick={handleNextDay}
                    aria-label="後一天"
                >
                    →
                </button>


                <button
                    type="button"
                    className="attendance-today-button"
                    onClick={handleToday}
                >
                    今天
                </button>

            </div>

        </header>
    );
}
