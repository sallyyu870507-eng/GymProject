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


export default function AttendancePage() {

    // ========================================
    // 日期
    // ========================================

    const [
        date,
        setDate
    ] =
        useState("2026-09-27");


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


    // ========================================
    // 日期改變
    // → GET Attendance List
    // ========================================

    useEffect(() => {

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


                setAttendanceList(data);


                const firstPendingCard =
                    data.classes.find(
                        card =>
                            card.bookingStatus
                                .toUpperCase()
                            !== "CANCELLED"
                            &&
                            card.attendanceStatus
                            === "PENDING"
                    );


                if (firstPendingCard) {

                    setSelectedBookingId(
                        firstPendingCard.bookingId
                    );

                } else {

                    setSelectedBookingId(null);

                }


            } catch (error) {

                console.error(
                    "載入 Attendance List 失敗：",
                    error
                );


                setError(
                    "出席資料載入失敗"
                );


            } finally {

                setLoading(false);

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

        setSaveMessage(null);

        setSaveError(null);


        setSelectedBookingId(
            bookingId
        );
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


        setSaving(true);

        setSaveMessage(null);

        setSaveError(null);


        try {

            await updateAttendance(
                bookingId,
                request
            );

        } catch (error) {

            console.error(
                "Attendance PUT 失敗：",
                error
            );


            setSaveError(
                "出席資料更新失敗，請稍後再試"
            );


            setSaving(false);

            return;
        }


        try {

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


            setAttendanceList(
                refreshedList
            );


            setSelectedDetail(
                refreshedDetail
            );


            setDetailVersion(
                version => version + 1
            );


            setSaveMessage(
                "出席資料更新成功"
            );


        } catch (error) {

            console.error(
                "Attendance 更新成功，但重新載入失敗：",
                error
            );


            setSaveError(
                "資料已更新，但重新載入最新資料失敗，請重新整理頁面"
            );


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
                    onDateChange={setDate}
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

                                        <h2>
                                            今日課程列表
                                        </h2>

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
                                                                    onSelect={
                                                                        handleSelectBooking
                                                                    }
                                                                />
                                                            )
                                                        )
                                                }

                                            </div>
                                        )
                                }

                            </section>


                            {
                                selectedBookingId
                                === null
                                &&
                                attendanceList
                                    .classes
                                    .length
                                > 0
                                && (
                                    <div className="attendance-page-state">
                                        請選擇一堂課查看出席明細
                                    </div>
                                )
                            }


                            {
                                detailLoading && (
                                    <div className="attendance-page-state">
                                        出席明細載入中...
                                    </div>
                                )
                            }


                            {
                                detailError && (
                                    <div className="attendance-page-error">
                                        {detailError}
                                    </div>
                                )
                            }


                            {
                                !detailLoading
                                &&
                                !detailError
                                &&
                                selectedDetail
                                && (
                                    <AttendanceDetail
                                        detail={
                                            selectedDetail
                                        }
                                        detailVersion={
                                            detailVersion
                                        }
                                        onSave={
                                            handleSaveAttendance
                                        }
                                        saving={
                                            saving
                                        }
                                        saveMessage={
                                            saveMessage
                                        }
                                        saveError={
                                            saveError
                                        }
                                    />
                                )
                            }

                        </>
                    )
                }

            </div>

        </main>
    );
}