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

    const today =
        new Date();


    const year =
        today.getFullYear();

    const month =
        String(
            today.getMonth() + 1
        ).padStart(2, "0");

    const day =
        String(
            today.getDate()
        ).padStart(2, "0");


    return `${year}-${month}-${day}`;
}


export default function AttendanceHeader(
    {
        date,
        onDateChange
    }: AttendanceHeaderProps
) {

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


                <label className="attendance-date-picker">

                    <span>
                        {formatDisplayDate(date)}
                    </span>

                    <input
                        type="date"
                        value={date}
                        onChange={
                            event =>
                                onDateChange(
                                    event.target.value
                                )
                        }
                    />

                </label>


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