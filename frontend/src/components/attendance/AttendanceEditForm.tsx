import { confirmDialog } from '../../notifications.js';
import {
    useEffect,
    useRef,
    useState
} from "react";

import type {
    AttendanceDetailResponse,
    AttendanceUpdateRequest,
    AttendanceUpdateStatus
} from "../../types/Attendance";

import AttendanceStatusSelector
    from "./AttendanceStatusSelector";

import "./AttendanceEditForm.css";


interface AttendanceEditFormProps {

    detail: AttendanceDetailResponse;

    onSave: (
        request: AttendanceUpdateRequest
    ) => Promise<void>;

    saving: boolean;

    saveMessage: string | null;

    saveError: string | null;

    onDirtyChange: (dirty: boolean) => void;
}


export default function AttendanceEditForm(
    {
        detail,
        onSave,
        saving,
        saveMessage,
        saveError,
        onDirtyChange
    }: AttendanceEditFormProps
) {

    /* =========================================================
       Status

       PENDING：
       還沒有正式出席結果，
       所以前端先用空字串表示「尚未選擇」。

       其餘：
       PRESENT / LEAVE / ABSENT
       直接帶入目前資料。
       ========================================================= */

    const [
        status,
        setStatus
    ] =
        useState<
            AttendanceUpdateStatus
            | ""
        >(
            detail.attendance.status
            === "PENDING"
                ? ""
                : detail.attendance.status as AttendanceUpdateStatus
);


    /* =========================================================
       Workout / Note
       ========================================================= */

    const [
        workoutFocus,
        setWorkoutFocus
    ] =
        useState(
            detail.attendance.workoutFocus
            ?? ""
        );


    const [
        note,
        setNote
    ] =
        useState(
            detail.attendance.note
            ?? ""
        );


    /* =========================================================
       InBody
       ========================================================= */

    const [
        weight,
        setWeight
    ] =
        useState(
            detail.attendance.inBody
                ?.weight
                ?.toString()
            ?? ""
        );


    const [
        bodyFatPct,
        setBodyFatPct
    ] =
        useState(
            detail.attendance.inBody
                ?.bodyFatPct
                ?.toString()
            ?? ""
        );


    const [
        muscleMass,
        setMuscleMass
    ] =
        useState(
            detail.attendance.inBody
                ?.muscleMass
                ?.toString()
            ?? ""
        );

    const initialValues = useRef({
        status: detail.attendance.status === "PENDING" ? "" : detail.attendance.status,
        workoutFocus: detail.attendance.workoutFocus ?? "",
        note: detail.attendance.note ?? "",
        weight: detail.attendance.inBody?.weight?.toString() ?? "",
        bodyFatPct: detail.attendance.inBody?.bodyFatPct?.toString() ?? "",
        muscleMass: detail.attendance.inBody?.muscleMass?.toString() ?? ""
    });

    const isDirty = status !== initialValues.current.status
        || workoutFocus !== initialValues.current.workoutFocus
        || note !== initialValues.current.note
        || weight !== initialValues.current.weight
        || bodyFatPct !== initialValues.current.bodyFatPct
        || muscleMass !== initialValues.current.muscleMass;

    useEffect(() => {
        onDirtyChange(isDirty);
    }, [isDirty, onDirtyChange]);


    /* =========================================================
       Validation Error
       ========================================================= */

    const [
        formError,
        setFormError
    ] =
        useState<string | null>(
            null
        );


    /* =========================================================
       Status Change

       只改前端 state。
       剩餘堂數仍由後端 Service 處理。
       ========================================================= */

    async function handleStatusChange(
        newStatus: AttendanceUpdateStatus
    ) {

        if (newStatus === status) {
            return;
        }

        const isLeavingPresent = newStatus !== "PRESENT";
        const hasTrainingOrInBody = [
            workoutFocus,
            weight,
            bodyFatPct,
            muscleMass
        ].some(value => value.trim() !== "");

        if (isLeavingPresent && hasTrainingOrInBody) {
            const confirmed = await confirmDialog(
                "改為請假或未出席後，儲存時將清除本次訓練重點\n與 InBody 資料，是否繼續？"
            );

            if (!confirmed) {
                return;
            }

            setWorkoutFocus("");
            setWeight("");
            setBodyFatPct("");
            setMuscleMass("");
        }

        setStatus(
            newStatus
        );


        setFormError(
            null
        );
    }


    /* =========================================================
       Submit
       ========================================================= */

    async function handleSubmit(
        event:
        React.FormEvent<HTMLFormElement>
    ) {

        event.preventDefault();


        if (saving) {
            return;
        }


        setFormError(
            null
        );


        /* =====================================================
           1. Status 必填
           ===================================================== */

        if (status === "") {

            setFormError(
                "請先選擇出席狀態"
            );

            return;
        }


        /* =====================================================
           2. InBody

           只有 PRESENT 才處理。

           全空：
           → null

           只填部分：
           → 前端擋住

           三個都有：
           → 驗證 number > 0
           ===================================================== */

        let inBody:
            AttendanceUpdateRequest["inBody"]
            =
            null;


        if (status === "PRESENT") {

            const hasWeight =
                weight.trim() !== "";

            const hasBodyFatPct =
                bodyFatPct.trim() !== "";

            const hasMuscleMass =
                muscleMass.trim() !== "";


            const hasAnyInBody =
                hasWeight
                ||
                hasBodyFatPct
                ||
                hasMuscleMass;


            const hasAllInBody =
                hasWeight
                &&
                hasBodyFatPct
                &&
                hasMuscleMass;


            if (!hasAnyInBody) {

                inBody = null;

            } else if (!hasAllInBody) {

                setFormError(
                    "InBody 若有填寫，體重、體脂率、肌肉量三個欄位都必須填寫"
                );

                return;

            } else {

                const weightNumber =
                    Number(weight);

                const bodyFatPctNumber =
                    Number(bodyFatPct);

                const muscleMassNumber =
                    Number(muscleMass);


                if (
                    !Number.isFinite(
                        weightNumber
                    )
                    ||
                    !Number.isFinite(
                        bodyFatPctNumber
                    )
                    ||
                    !Number.isFinite(
                        muscleMassNumber
                    )
                ) {

                    setFormError(
                        "InBody 必須輸入有效數字"
                    );

                    return;
                }


                if (
                    weightNumber <= 0
                    ||
                    bodyFatPctNumber <= 0
                    ||
                    muscleMassNumber <= 0
                ) {

                    setFormError(
                        "InBody 數值必須大於 0"
                    );

                    return;
                }


                inBody = {

                    weight:
                    weightNumber,

                    bodyFatPct:
                    bodyFatPctNumber,

                    muscleMass:
                    muscleMassNumber
                };

            }
        }


        /* =====================================================
           3. Request

           PRESENT：
           workoutFocus 可以送

           LEAVE / ABSENT：
           workoutFocus = null
           inBody = null

           note：
           三種狀態都可以送
           ===================================================== */

        const request:
            AttendanceUpdateRequest
            = {

            status,

            workoutFocus:
                status === "PRESENT"
                    ? (
                        workoutFocus.trim()
                        || null
                    )
                    : null,

            note:
                note.trim()
                || null,

            inBody:
                status === "PRESENT"
                    ? inBody
                    : null
        };


        await onSave(
            request
        );
    }


    return (
        <form
            className="attendance-edit-form"
            onSubmit={handleSubmit}
        >

            {/* =================================================
                Status
            ================================================= */}

            <section className="attendance-edit-section">

                <div className="attendance-edit-section-header">

                    <div>

                        <h3>
                            出席紀錄
                        </h3>

                        <p>
                            選擇本次課程的實際出席狀態
                        </p>

                    </div>

                </div>


                <div className="attendance-form-group">

                    <label>
                        出席狀態
                    </label>


                    <AttendanceStatusSelector
                        status={status}
                        onChange={
                            handleStatusChange
                        }
                        disabled={saving}
                    />

                </div>

            </section>


            {/* =================================================
                Workout + Note
            ================================================= */}

            <section className="attendance-edit-section">

                <div className="attendance-edit-section-header">

                    <div>

                        <h3>
                            本次訓練紀錄
                        </h3>

                        <p>
                            紀錄本堂課的訓練內容與補充資訊
                        </p>

                    </div>

                </div>


                <div className="attendance-training-grid">

                    {/* Workout Focus */}

                    <div className="attendance-form-group">

                        <label
                            htmlFor="attendance-workout-focus"
                        >
                            訓練重點
                        </label>


                        <input
                            id="attendance-workout-focus"
                            type="text"
                            value={
                                workoutFocus
                            }
                            onChange={
                                event =>
                                    setWorkoutFocus(
                                        event.target.value
                                    )
                            }
                            disabled={
                                status !== "PRESENT"
                                ||
                                saving
                            }
                            placeholder={
                                status === "PRESENT"
                                    ? "例如：下肢訓練、核心訓練"
                                    : "僅已出席可填寫"
                            }
                        />

                    </div>


                    {/* Note */}

                    <div className="attendance-form-group attendance-note-group">

                        <div className="attendance-field-label-row">

                            <label
                                htmlFor="attendance-note"
                            >
                                備註
                            </label>


                            <span className="attendance-note-count">
                                {note.length} 字
                            </span>

                        </div>


                        <textarea
                            id="attendance-note"
                            rows={4}
                            value={
                                note
                            }
                            onChange={
                                event =>
                                    setNote(
                                        event.target.value
                                    )
                            }
                            disabled={saving}
                            placeholder="輸入本次出席或訓練備註"
                        />

                    </div>

                </div>

            </section>


            {/* =================================================
                InBody
            ================================================= */}

            <section className="attendance-edit-section">

                <div className="attendance-edit-section-header">

                    <div>

                        <h3>
                            InBody 身體數據
                        </h3>

                        <p>
                            選填；若填寫，三個欄位皆需完整填寫
                        </p>

                    </div>


                    {
                        status !== "PRESENT"
                        && (
                            <span className="attendance-inbody-disabled-badge">
                                僅已出席可填寫
                            </span>
                        )
                    }

                </div>


                <fieldset
                    className="inbody-form"
                    disabled={
                        status !== "PRESENT"
                        ||
                        saving
                    }
                >

                    <div className="inbody-form-grid">

                        <div className="attendance-form-group">

                            <label
                                htmlFor="attendance-weight"
                            >
                                體重
                            </label>


                            <div className="attendance-input-with-unit">

                                <input
                                    id="attendance-weight"
                                    type="number"
                                    step="0.1"
                                    value={
                                        weight
                                    }
                                    onChange={
                                        event =>
                                            setWeight(
                                                event.target.value
                                            )
                                    }
                                    placeholder="0.0"
                                />


                                <span>
                                    kg
                                </span>

                            </div>

                        </div>


                        <div className="attendance-form-group">

                            <label
                                htmlFor="attendance-body-fat"
                            >
                                體脂率
                            </label>


                            <div className="attendance-input-with-unit">

                                <input
                                    id="attendance-body-fat"
                                    type="number"
                                    step="0.1"
                                    value={
                                        bodyFatPct
                                    }
                                    onChange={
                                        event =>
                                            setBodyFatPct(
                                                event.target.value
                                            )
                                    }
                                    placeholder="0.0"
                                />


                                <span>
                                    %
                                </span>

                            </div>

                        </div>


                        <div className="attendance-form-group">

                            <label
                                htmlFor="attendance-muscle-mass"
                            >
                                肌肉量
                            </label>


                            <div className="attendance-input-with-unit">

                                <input
                                    id="attendance-muscle-mass"
                                    type="number"
                                    step="0.1"
                                    value={
                                        muscleMass
                                    }
                                    onChange={
                                        event =>
                                            setMuscleMass(
                                                event.target.value
                                            )
                                    }
                                    placeholder="0.0"
                                />


                                <span>
                                    kg
                                </span>

                            </div>

                        </div>

                    </div>

                </fieldset>

            </section>


            {/* =================================================
                Messages
            ================================================= */}

            {
                formError
                && (
                    <div className="attendance-form-error">
                        {formError}
                    </div>
                )
            }


            {
                saveError
                && (
                    <div className="attendance-save-error">
                        {saveError}
                    </div>
                )
            }


            {
                saveMessage
                && (
                    <div className="attendance-save-success">
                        {saveMessage}
                    </div>
                )
            }


            {/* =================================================
                Save
            ================================================= */}

            <div className="attendance-form-actions">

                <button
                    type="submit"
                    className="attendance-save-button"
                    disabled={saving}
                >

                    {
                        saving
                            ? "儲存中..."
                            : "儲存出席資料"
                    }

                </button>

            </div>

        </form>
    );
}
