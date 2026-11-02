import type { ReactNode } from "react";
import type { RenewalOverviewResponse } from "../../types/Renewal";
import "./RenewalPlanIdentity.css";

type Props = {
    plan: RenewalOverviewResponse | null;
    backLabel: string;
    onBack: () => void;
    backDisabled?: boolean;
    actions?: ReactNode;
};

function displayGender(value: string | null) {
    if (!value) return "—";
    const normalized = value.toUpperCase();
    if (["F", "FEMALE", "女"].includes(normalized)) return "女";
    if (["M", "MALE", "男"].includes(normalized)) return "男";
    return value;
}

function MemberIcon({ name }: { name: "gender" | "phone" | "email" }) {
    if (name === "gender") return <svg className="renewal-plan-member-icon renewal-plan-member-icon-gender" viewBox="0 0 24 24" aria-hidden="true"><text x="12" y="20" textAnchor="middle" fill="currentColor" fontSize="22">♀</text></svg>;
    if (name === "phone") return <svg className="renewal-plan-member-icon" viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M6.6 10.8a15.5 15.5 0 0 0 6.6 6.6l2.2-2.2a1 1 0 0 1 1.02-.24c1.12.37 2.32.57 3.58.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1C10.6 21 3 13.4 3 4c0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.26.2 2.46.57 3.58a1 1 0 0 1-.24 1.02l-2.23 2.2Z" /></svg>;
    return <svg className="renewal-plan-member-icon" viewBox="0 0 24 24" aria-hidden="true"><rect x="2.5" y="4.5" width="19" height="15" rx="2" fill="none" stroke="currentColor" strokeWidth="1.8" /><path d="m3.5 6 8.5 7 8.5-7" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /></svg>;
}

export default function RenewalPlanIdentity({ plan, backLabel, onBack, backDisabled = false, actions }: Props) {
    return <section className="renewal-plan-identity" aria-label="方案與會員摘要">
        <div className="renewal-plan-identity-title-row">
            <div className="renewal-plan-identity-title-group">
                <button className="renewal-plan-identity-back" type="button" onClick={onBack} disabled={backDisabled}>← <span>{backLabel}</span></button>
                {plan && <h2 className="renewal-plan-name">{plan.member.name || "—"}・{plan.course.courseName || "—"}・方案 #{plan.memberCourseId}</h2>}
            </div>
            {actions}
        </div>

        {plan && <div className="renewal-plan-member-strip" aria-label="會員摘要">
            {plan.member.avatarUrl ? <img className="renewal-plan-avatar" src={plan.member.avatarUrl} alt="" /> :
                <span className="renewal-plan-avatar renewal-plan-avatar-fallback" aria-hidden="true">{plan.member.name?.slice(0, 1) || "?"}</span>}
            <strong className="renewal-plan-strip-name">{plan.member.name || "—"}</strong>
            <span className="renewal-plan-strip-item"><MemberIcon name="gender" />{displayGender(plan.member.gender)}</span>
            <span className="renewal-plan-strip-item">{plan.member.age === null ? "—" : `${plan.member.age} 歲`}</span>
            <span className="renewal-plan-strip-item"><MemberIcon name="phone" />{plan.member.phone || "—"}</span>
            <span className="renewal-plan-strip-item renewal-plan-strip-email"><MemberIcon name="email" />{plan.member.email || "—"}</span>
        </div>}
    </section>;
}
