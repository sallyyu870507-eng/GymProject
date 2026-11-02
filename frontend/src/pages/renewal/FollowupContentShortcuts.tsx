import { useState } from "react";
import { appendFollowupContentShortcut, FOLLOWUP_CONTENT_SHORTCUTS } from "./followupContentShortcutData.js";

type Props = {
    value: string;
    disabled: boolean;
    onChange: (value: string) => void;
};

export default function FollowupContentShortcuts({ value, disabled, onChange }: Props) {
    const [message, setMessage] = useState("");

    function append(sentence: string) {
        const next = appendFollowupContentShortcut(value, sentence);
        if (next === null) {
            setMessage("聯繫內容超過 500 字，無法加入此常用內容。");
            return;
        }
        setMessage("");
        if (next !== value) onChange(next);
    }

    return <div className="renewal-followup-shortcuts">
        <span className="renewal-followup-shortcuts-label">常用句快捷輸入</span>
        <span className="renewal-followup-shortcuts-description">點擊可加入多句，帶入後可自行修改或刪除，儲存前請確認內容。</span>
        <div className="renewal-followup-shortcuts-list" role="group" aria-label="常用聯繫內容">
            {FOLLOWUP_CONTENT_SHORTCUTS.map(({ label, text }) => <button
                key={label}
                type="button"
                disabled={disabled}
                onClick={() => append(text)}
            >{label}</button>)}
        </div>
        <span className="renewal-followup-shortcuts-message" role="status" aria-live="polite">{message}</span>
    </div>;
}
