export type RenewalScope = "TRACKING" | "ALL_PLANS";

export type RenewalCategory =
    | "ALL"
    | "HIGH_PRIORITY"
    | "UPCOMING"
    | "LONG_ABSENT"
    | "COMPLETED";

export type RenewalFollowupStatus =
    | "ALL"
    | "NOT_CONTACTED"
    | "NO_RESPONSE"
    | "CONSIDERING"
    | "AGREED"
    | "DECLINED";

export type RenewalTag = Exclude<RenewalCategory, "ALL"> | string;

export type RenewalWorkbenchItem = {
    memberCourseId: number;
    memberId: number;
    name: string;
    avatarUrl: string | null;
    memberStatus: "active" | "inactive" | string;
    courseId: number;
    courseName: string;
    coachId: number;
    purchaseDate: string;
    totalSessions: number;
    remainingSessions: number;
    status: "active" | "usedup" | string;
    courseActivity: {
        lastPresentDate: string | null;
        daysSinceLastPresent: number | null;
        baselineType: "LAST_PRESENT" | "FIRST_PURCHASE" | string | null;
        baselineDate: string | null;
        daysSinceBaseline: number | null;
    } | null;
    tags: RenewalTag[];
    hasRenewed: boolean;
    outgoingRenewals: Array<{
        renewalId: number;
        newMemberCourseId: number;
        courseId: number;
        courseName: string;
        purchaseDate: string;
        renewalDate: string;
    }>;
    followupStatus: string | null;
    latestFollowupDate: string | null;
};

export type RenewalWorkbenchResponse = {
    asOfDate: string;
    counts: {
        highPriority: number;
        upcoming: number;
        longAbsent: number;
        completed: number;
    };
    authorizedPlanCount: number;
    trackingPlanCount: number;
    items: RenewalWorkbenchItem[];
    page: {
        number: number;
        size: number;
        totalElements: number;
        totalPages: number;
        hasPrevious: boolean;
        hasNext: boolean;
    };
};

export type RenewalOverviewResponse = {
    asOfDate: string;
    asOfDateTime: string;
    memberCourseId: number;
    member: {
        memberId: number;
        name: string;
        avatarUrl: string | null;
        gender: string | null;
        age: number | null;
        phone: string | null;
        email: string | null;
        status: string;
    };
    course: {
        courseId: number;
        courseName: string;
        coachId: number;
        coachName: string;
        purchaseDate: string;
        totalSessions: number;
        remainingSessions: number;
        usedSessions: number;
        status: string;
    };
    courseActivity: {
        lastPresentDate: string | null;
        daysSinceLastPresent: number | null;
        baselineType: string | null;
        baselineDate: string | null;
        daysSinceBaseline: number | null;
    } | null;
    tags: RenewalTag[];
    hasRenewed: boolean;
    outgoingRenewals: RenewalWorkbenchItem["outgoingRenewals"];
    followupStatus: string | null;
    reminders: Array<{ type: string; message: string }>;
    actions: {
        canAddFollowup: boolean;
        canRenew: boolean;
        renewDisabledReason: string | null;
    };
};

export type FollowupRecord = {
    followupId: number;
    memberCourseId: number;
    createdDate: string | null;
    coachId: number | null;
    coachName: string | null;
    contactMethod: string | null;
    status: string | null;
    note: string | null;
};

export type FollowupPageResponse = {
    memberCourseId: number;
    items: FollowupRecord[];
    page: {
        number: number;
        size: number;
        totalElements: number;
        totalPages: number;
        hasPrevious: boolean;
        hasNext: boolean;
    };
    latestFollowup: FollowupRecord | null;
};

export type AttendanceSummary = {
    memberCourseId: number;
    asOfDateTime: string;
    presentCount: number;
    leaveCount: number;
    absentCount: number;
};

export type InBodyRecord = {
    inBodyId: number;
    attendanceId: number;
    recordDate: string | null;
    classStartDateTime: string;
    weight: number | null;
    bodyFatPct: number | null;
    muscleMass: number | null;
};

export type InBodyTrendPoint = {
    inBodyId: number;
    attendanceId: number;
    recordDate: string;
    classStartDateTime: string;
    value: number;
};

export type InBodyPageResponse = {
    memberCourseId: number;
    asOfDateTime: string;
    latestRecord: InBodyRecord | null;
    trends: {
        weight: InBodyTrendPoint[];
        bodyFatPct: InBodyTrendPoint[];
        muscleMass: InBodyTrendPoint[];
    };
    items: InBodyRecord[];
    page: {
        number: number;
        size: number;
        totalElements: number;
        totalPages: number;
        hasPrevious: boolean;
        hasNext: boolean;
    };
};

export type RenewalOptionsResponse = {
    memberCourseId: number;
    asOfDateTime: string;
    today: string;
    member: { memberId: number; name: string; status: string };
    sourceCourse: {
        courseId: number;
        courseName: string;
        purchaseDate: string;
        totalSessions: number;
        remainingSessions: number;
        coachId: number;
        coachName: string;
    };
    coach: { coachId: number; coachName: string };
    courses: Array<{ courseId: number; courseName: string }>;
    defaultCourseId: number | null;
    defaultPurchaseDate: string;
    minPurchaseDate: string;
    maxPurchaseDate: string;
    paymentMethods: Array<{ value: string; label: string }>;
    canSubmit: boolean;
    disabledReason: string | null;
};

export type RenewalCreateRequest = {
    courseId: number;
    addedSessions: number;
    amount: number;
    paymentMethod: string;
    purchaseDate: string;
    note: string | null;
};

export type RenewalCreateResponse = {
    renewalId: number;
    sourceMemberCourseId: number;
    newMemberCourseId: number;
    memberId: number;
    courseId: number;
    courseName: string;
    coachId: number;
    coachName: string;
    purchaseDate: string;
    renewalDate: string;
    addedSessions: number;
    totalSessions: number;
    remainingSessions: number;
    status: string;
    amount: number;
    paymentMethod: string;
    note: string | null;
};
