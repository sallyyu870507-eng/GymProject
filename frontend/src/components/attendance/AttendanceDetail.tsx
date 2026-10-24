import type {
    AttendanceDetailResponse,
    AttendanceUpdateRequest
} from "../../types/Attendance";

import AttendanceEditForm
    from "./AttendanceEditForm";

import AttendanceHistory
    from "./AttendanceHistory";


interface AttendanceDetailProps {
    detail: AttendanceDetailResponse;

    detailVersion: number;

    onSave: (
        request: AttendanceUpdateRequest
    ) => Promise<void>;

    saving: boolean;

    saveMessage: string | null;

    saveError: string | null;

    onDirtyChange: (dirty: boolean) => void;
}


function getGenderLabel(
    gender: string | null
) {

    if (!gender) {
        return "未填寫";
    }


    switch (
        gender.toUpperCase()
        ) {

        case "M":
        case "MALE":
            return "男";

        case "F":
        case "FEMALE":
            return "女";

        default:
            return gender;
    }
}


function getMemberInitial(
    name: string
) {

    const trimmedName =
        name.trim();


    return trimmedName
        ? trimmedName.charAt(0)
        : "會";
}


export default function AttendanceDetail(
    {
        detail,
        detailVersion,
        onSave,
        saving,
        saveMessage,
        saveError,
        onDirtyChange
    }: AttendanceDetailProps
) {

    return (
        <section className="attendance-workspace">

            {/* =====================================================
                Left
                學員出席處理
            ===================================================== */}

            <div className="attendance-student-panel">

                <div className="attendance-panel-header">

                    <h2>
                        學員出席處理
                    </h2>

                </div>


                {/* =========================
                    Member + Course
                ========================= */}

                <div className="attendance-student-overview">

                    <div className="attendance-student-profile">

                        <div className="attendance-detail-avatar">

                            {
                                detail.member.avatarUrl
                                    ? (
                                        <img
                                            src={
                                                detail.member.avatarUrl
                                            }
                                            alt={
                                                detail.member.name
                                            }
                                        />
                                    )
                                    : (
                                        <span>
                                            {
                                                getMemberInitial(
                                                    detail.member.name
                                                )
                                            }
                                        </span>
                                    )
                            }

                        </div>


                        <div className="attendance-student-info">

                            <h3>
                                {detail.member.name}
                            </h3>


                            <div className="attendance-student-meta">

                                <span>
                                    {
                                        getGenderLabel(
                                            detail.member.gender
                                        )
                                    }
                                </span>


                                <span>
                                    {detail.member.phone}
                                </span>


                                <span>
                                    {detail.member.email}
                                </span>

                            </div>

                        </div>

                    </div>


                    <div className="attendance-course-overview">

                        <div className="attendance-course-overview-item">

                            <span>
                                課程方案
                            </span>

                            <strong>
                                {
                                    detail.course.courseName
                                }
                            </strong>

                        </div>


                        <div className="attendance-course-overview-item">

                            <span>
                                剩餘堂數
                            </span>

                            <strong className="attendance-remaining-value">

                                {
                                    detail.course
                                        .remainingSessions
                                }

                                <small>
                                    堂
                                </small>

                            </strong>

                        </div>


                        <div className="attendance-course-overview-item">

                            <span>
                                上次出席
                            </span>

                            <strong>

                                {
                                    detail.course
                                        .lastPresentDate
                                    ?? "尚無紀錄"
                                }

                            </strong>

                        </div>

                    </div>

                </div>


                {/* =========================
                    Edit Form
                    UI-D / UI-E 再重做內部樣式
                ========================= */}

                <div className="attendance-student-form">

                    <AttendanceEditForm
                        key={detailVersion}
                        detail={detail}
                        onSave={onSave}
                        saving={saving}
                        saveMessage={saveMessage}
                        saveError={saveError}
                        onDirtyChange={onDirtyChange}
                    />

                </div>

            </div>


            {/* =====================================================
                Right
                History
            ===================================================== */}

            <AttendanceHistory
                history={detail.history}
            />

        </section>
    );
}
