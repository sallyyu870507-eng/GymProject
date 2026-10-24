import {
    useEffect,
    useRef,
    useState
} from "react";

import {
    getAttendanceDetail,
    getAttendanceList,
    updateAttendance
} from "../../services/attendanceService";

import type {
    AttendanceDetailResponse,
    AttendanceListResponse,
    AttendanceUpdateRequest
} from "../../types/Attendance";

import AttendanceHeader
    from "../../components/attendance/AttendanceHeader";

import AttendanceSummary
    from "../../components/attendance/AttendanceSummary";

import AttendanceCard
    from "../../components/attendance/AttendanceCard";

import AttendanceDetail
    from "../../components/attendance/AttendanceDetail";

import "./AttendancePage.css";


function getTaipeiToday(): string {
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


export default function AttendancePage() {

    // ========================================
    // 日期
    // ========================================

    const [
        date,
        setDate
    ] =
        useState(getTaipeiToday);


    // ========================================
    // List
    // ========================================

    const [
        attendanceList,
        setAttendanceList
    ] =
        useState<AttendanceListResponse | null>(
            null
        );


    const [
        loading,
        setLoading
    ] =
        useState(false);


    const [
        error,
        setError
    ] =
        useState<string | null>(null);


    // ========================================
    // Selected Booking
    // ========================================

    const [
        selectedBookingId,
        setSelectedBookingId
    ] =
        useState<number | null>(null);


    // ========================================
    // Detail
    // ========================================

    const [
        selectedDetail,
        setSelectedDetail
    ] =
        useState<AttendanceDetailResponse | null>(
            null
        );


    const [
        detailVersion,
        setDetailVersion
    ] =
        useState(0);


    const [
        detailLoading,
        setDetailLoading
    ] =
        useState(false);


    const [
        detailError,
        setDetailError
    ] =
        useState<string | null>(null);


    // ========================================
    // Save
    // ========================================

    const [
        saving,
        setSaving
    ] =
        useState(false);

    const [formDirty, setFormDirty] = useState(false);


    const [
        saveMessage,
        setSaveMessage
    ] =
        useState<string | null>(null);


    const [
        saveError,
        setSaveError
    ] =
        useState<string | null>(null);


    // ========================================
    // 防止舊 Detail Request
    // 蓋掉最新選取會員
    // ========================================

    const detailRequestIdRef =
        useRef(0);

    const listRequestIdRef =
        useRef(0);

    const currentDateRef =
        useRef(date);

    const selectedBookingIdRef =
        useRef<number | null>(selectedBookingId);

    const selectionVersionRef =
        useRef(0);


    function handleDateChange(nextDate: string) {
        if (!nextDate || nextDate === currentDateRef.current) return;

        if (formDirty && !window.confirm("出席表單有尚未儲存的內容，確定捨棄並切換日期嗎？")) return;

        currentDateRef.current = nextDate;
        selectedBookingIdRef.current = null;
        selectionVersionRef.current += 1;
        listRequestIdRef.current += 1;
        detailRequestIdRef.current += 1;

        setDate(nextDate);
        setAttendanceList(null);
        setSelectedBookingId(null);
        setSelectedDetail(null);
        setDetailError(null);
        setDetailLoading(false);
        setSaveMessage(null);
        setSaveError(null);
        setFormDirty(false);
    }


    // ========================================
    // 日期改變
    // → GET Attendance List
    // ========================================

    useEffect(() => {

        const requestId = ++listRequestIdRef.current;

        async function loadAttendanceList() {

            try {

                setLoading(true);

                setError(null);

                setAttendanceList(null);

                setSelectedBookingId(null);

                setSelectedDetail(null);

                setDetailError(null);

                setDetailLoading(false);

                setSaveMessage(null);

                setSaveError(null);


                const data =
                    await getAttendanceList(date);

                if (requestId !== listRequestIdRef.current) return;
                setAttendanceList(data);

            } catch (error) {

                if (requestId !== listRequestIdRef.current) return;

                console.error(
                    "載入 Attendance List 失敗：",
                    error
                );


                setError(
                    "出席資料載入失敗"
                );


            } finally {
                if (requestId === listRequestIdRef.current) setLoading(false);

            }
        }


        loadAttendanceList();

    }, [date]);


    // ========================================
    // selectedBookingId 改變
    // → GET Detail
    // ========================================

    useEffect(() => {

        const requestId =
            ++detailRequestIdRef.current;


        async function loadAttendanceDetail() {

            if (selectedBookingId === null) {

                setSelectedDetail(null);

                setDetailError(null);

                setDetailLoading(false);

                return;
            }


            try {

                setDetailLoading(true);

                setDetailError(null);

                setSelectedDetail(null);


                const data =
                    await getAttendanceDetail(
                        selectedBookingId
                    );


                if (
                    requestId
                    !==
                    detailRequestIdRef.current
                ) {

                    return;
                }


                setSelectedDetail(data);


                setDetailVersion(
                    version => version + 1
                );


            } catch (error) {

                if (
                    requestId
                    !==
                    detailRequestIdRef.current
                ) {

                    return;
                }


                console.error(
                    "載入 Attendance Detail 失敗：",
                    error
                );


                setSelectedDetail(null);


                setDetailError(
                    "出席明細載入失敗"
                );


            } finally {

                if (
                    requestId
                    ===
                    detailRequestIdRef.current
                ) {

                    setDetailLoading(false);
                }

            }
        }


        loadAttendanceDetail();

    }, [selectedBookingId]);


    // ========================================
    // 點選 Card
    // ========================================

    function handleSelectBooking(
        bookingId: number
    ) {

        const isCurrentSelection = selectedBookingIdRef.current === bookingId;
        if (formDirty && !window.confirm("出席表單有尚未儲存的內容，確定捨棄並切換課程嗎？")) return;

        if (isCurrentSelection) {
            selectedBookingIdRef.current = null;
            selectionVersionRef.current += 1;
            detailRequestIdRef.current += 1;
            setSelectedBookingId(null);
            setSelectedDetail(null);
            setDetailError(null);
            setDetailLoading(false);
            setSaveMessage(null);
            setSaveError(null);
            setFormDirty(false);
            return;
        }

        selectedBookingIdRef.current = bookingId;
        selectionVersionRef.current += 1;
        detailRequestIdRef.current += 1;

        setSaveMessage(null);

        setSaveError(null);


        setSelectedBookingId(
            bookingId
        );
        setSelectedDetail(null);
        setDetailError(null);
        setDetailLoading(true);
        setFormDirty(false);
    }


    // ========================================
    // PUT
    // → Reload List + Detail
    // ========================================

    async function handleSaveAttendance(
        request: AttendanceUpdateRequest
    ) {

        if (
            selectedBookingId === null
            ||
            saving
        ) {

            return;
        }


        const bookingId =
            selectedBookingId;
        const savedDate = date;
        const selectionVersion = selectionVersionRef.current;


        setSaving(true);

        setSaveMessage(null);

        setSaveError(null);


        try {

            await updateAttendance(
                bookingId,
                request
            );

            if (currentDateRef.current === savedDate && selectionVersionRef.current === selectionVersion) {
                setFormDirty(false);
            }

        } catch (error) {

            console.error(
                "Attendance PUT 失敗：",
                error
            );


            if (currentDateRef.current === savedDate && selectionVersionRef.current === selectionVersion) {
                setSaveError("出席資料更新失敗，請稍後再試");
            }


            setSaving(false);

            return;
        }


        try {

            if (currentDateRef.current !== savedDate || selectionVersionRef.current !== selectionVersion) return;

            const [
                refreshedList,
                refreshedDetail
            ] =
                await Promise.all([
                    getAttendanceList(date),
                    getAttendanceDetail(
                        bookingId
                    )
                ]);

            if (currentDateRef.current !== savedDate || selectionVersionRef.current !== selectionVersion) return;

            const retainedCard = refreshedList.classes.find(
                card => card.bookingId === bookingId && card.bookingStatus.toUpperCase() !== "CANCELLED"
            );


            setAttendanceList(
                refreshedList
            );

            if (retainedCard) {
                setSelectedDetail(refreshedDetail);
                setDetailVersion(version => version + 1);
                setSaveMessage("出席資料更新成功");
            } else {
                selectedBookingIdRef.current = null;
                selectionVersionRef.current += 1;
                detailRequestIdRef.current += 1;
                setSelectedBookingId(null);
                setSelectedDetail(null);
                setDetailError(null);
                setSaveMessage("出席資料更新成功；此課程已不在目前列表");
            }


        } catch (error) {

            console.error(
                "Attendance 更新成功，但重新載入失敗：",
                error
            );


            if (currentDateRef.current === savedDate && selectionVersionRef.current === selectionVersion) {
                setSaveError("資料已更新，但重新載入最新資料失敗，請重新整理頁面");
            }


        } finally {

            setSaving(false);

        }
    }


    return (
        <main className="attendance-page">

            <div className="attendance-page-container">

                {/* =========================
                    UI-A
                    Header
                ========================= */}

                <AttendanceHeader
                    date={date}
                    onDateChange={handleDateChange}
                />


                {
                    loading && (
                        <div className="attendance-page-state">
                            資料載入中...
                        </div>
                    )
                }


                {
                    error && (
                        <div className="attendance-page-error">
                            {error}
                        </div>
                    )
                }


                {
                    !loading
                    &&
                    !error
                    &&
                    attendanceList
                    && (
                        <>

                            {/* =========================
                                UI-B
                                Summary
                            ========================= */}

                            <AttendanceSummary
                                summary={
                                    attendanceList.summary
                                }
                            />


                            {/* =========================
                                UI-B
                                今日課程列表
                            ========================= */}

                            <section className="attendance-course-section">

                                <div className="attendance-section-header">

                                    <div>

                                        <div className="attendance-section-title-row">
                                            <h2>今日課程列表</h2>
                                            <span className="attendance-course-hint">點選課程以處理出席</span>
                                        </div>

                                        <p>
                                            共{" "}
                                            {
                                                attendanceList
                                                    .summary
                                                    .totalClasses
                                            }{" "}
                                            堂課程
                                        </p>

                                    </div>

                                </div>


                                {
                                    attendanceList
                                        .classes
                                        .length
                                    === 0
                                        ? (
                                            <div className="attendance-page-state">
                                                當日無課程
                                            </div>
                                        )
                                        : (
                                            <div className="attendance-card-list">

                                                {
                                                    attendanceList
                                                        .classes
                                                        .map(
                                                            card => (
                                                                <AttendanceCard
                                                                    key={
                                                                        card.bookingId
                                                                    }
                                                                    card={
                                                                        card
                                                                    }
                                                                    selected={
                                                                        selectedBookingId
                                                                        ===
                                                                        card.bookingId
                                                                    }
                                                                    onSelect={handleSelectBooking}
                                                                />
                                                            )
                                                        )
                                                }

                                            </div>
                                        )
                                }

                            </section>


                            {selectedBookingId !== null && (
                                <div id="attendance-selection-panel">
                                    {detailLoading && <div className="attendance-page-state" role="status">出席明細載入中...</div>}
                                    {detailError && <div className="attendance-page-error" role="alert">{detailError}</div>}
                                    {!detailLoading && !detailError && selectedDetail && (
                                        <AttendanceDetail
                                            detail={selectedDetail}
                                            detailVersion={detailVersion}
                                            onSave={handleSaveAttendance}
                                            saving={saving}
                                            saveMessage={saveMessage}
                                            saveError={saveError}
                                            onDirtyChange={setFormDirty}
                                        />
                                    )}
                                </div>
                            )}

                        </>
                    )
                }

            </div>

        </main>
    );
}
