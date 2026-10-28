import { useEffect, useState } from "react";

import logo from "../../assets/power-gym-logo.jpg";
import "./Sidebar.css";

export type SidebarMenuKey =
    | "home"
    | "students"
    | "schedule"
    | "attendance"
    | "care"
    | "courses"
    | "coaches"
    | "my-bookings"
    | "booking"
    | "members";

type SidebarRole = "member" | "coach" | "admin";

type MenuItem = {
    key: SidebarMenuKey;
    label: string;
};

type SidebarProps = {
    isOpen?: boolean;
    onClose?: () => void;
    activeItem: SidebarMenuKey;
    onNavigate: (item: SidebarMenuKey) => void;
    availableItems: SidebarMenuKey[];
    navigationDisabled?: boolean;
    onUserNameChange?: (name: string) => void;
    role?: SidebarRole;
};

type UserPayload = {
    name?: unknown;
    role?: unknown;
};

const menuByRole: Record<SidebarRole, MenuItem[]> = {
    member: [
        { key: "home", label: "首頁" },
        { key: "courses", label: "課程總覽" },
        { key: "coaches", label: "教練介紹" },
        { key: "my-bookings", label: "我的預約" },
        { key: "booking", label: "預約課程" },
    ],
    coach: [
        { key: "home", label: "首頁" },
        { key: "students", label: "學員清單" },
        { key: "schedule", label: "我的課表" },
        { key: "attendance", label: "學員出席" },
        { key: "care", label: "續約與關懷" },
    ],
    admin: [
        { key: "members", label: "會員管理" },
        { key: "coaches", label: "教練管理" },
        { key: "courses", label: "課程管理" },
        { key: "schedule", label: "全館課表總覽" },
    ],
};

function parseRole(value: unknown): SidebarRole | null {
    if (typeof value !== "string") {
        return null;
    }

    const normalized = value.toLowerCase();
    return normalized === "member" || normalized === "coach" || normalized === "admin"
        ? normalized
        : null;
}

export default function Sidebar({
    isOpen = false,
    onClose,
    activeItem,
    onNavigate,
    availableItems,
    navigationDisabled = false,
    onUserNameChange,
    role = "coach",
}: SidebarProps) {
    const [userName, setUserName] = useState("");
    const [loginRole, setLoginRole] = useState<SidebarRole>(role);
    const [isLoggingOut, setIsLoggingOut] = useState(false);

    useEffect(() => {
        let isActive = true;

        async function loadCurrentUser() {
            try {
                const response = await fetch("/api/user", {
                    method: "GET",
                    credentials: "include",
                });

                if (!response.ok) {
                    throw new Error("無法取得登入者資料");
                }

                const data = (await response.json()) as UserPayload;
                if (!isActive) {
                    return;
                }

                const name = typeof data.name === "string" ? data.name : "";
                setUserName(name);
                onUserNameChange?.(name);
                setLoginRole(parseRole(data.role) ?? role);
            } catch (error) {
                console.error("取得登入者資料失敗：", error);
            }
        }

        void loadCurrentUser();
        return () => {
            isActive = false;
        };
    }, [onUserNameChange, role]);

    const menuItems = menuByRole[loginRole];

    function getWelcomeText() {
        if (loginRole === "member") {
            return userName ? `你好，${userName}會員` : "你好，會員";
        }
        if (loginRole === "coach") {
            return userName ? `你好，${userName}教練` : "你好，教練";
        }
        return "你好，管理員";
    }

    async function handleLogout() {
        if (isLoggingOut) {
            return;
        }

        try {
            setIsLoggingOut(true);
            const response = await fetch("http://localhost:8080/logout", {
                method: "POST",
                credentials: "include",
            });

            if (!response.ok) {
                throw new Error("登出失敗");
            }

            window.location.href = "http://localhost:8080/login";
        } catch (error) {
            console.error("登出失敗：", error);
            window.alert("登出失敗，請稍後再試");
        } finally {
            setIsLoggingOut(false);
        }
    }

    return (
        <aside id="gym-sidebar" className={`gym-sidebar${isOpen ? " is-open" : ""}`} aria-label="側邊導覽">
            <button type="button" className="gym-sidebar-close" aria-label="關閉導覽選單" onClick={onClose}>×</button>
            <div className="gym-sidebar-brand">
                <img src={logo} alt="POWER GYM 力量健身" className="gym-sidebar-logo" />
            </div>

            <div className="gym-sidebar-role-area">
                <span className="gym-sidebar-role-label">{getWelcomeText()}</span>
            </div>

            <nav className="gym-sidebar-menu" aria-label="主要導覽">
                {menuItems.map((item) => {
                    const isAvailable = availableItems.includes(item.key);
                    const isActive = activeItem === item.key;

                    return (
                        <button
                            key={item.key}
                            type="button"
                            className={`gym-sidebar-menu-item${isActive ? " is-active" : ""}`}
                            onClick={() => onNavigate(item.key)}
                            disabled={!isAvailable || navigationDisabled}
                            aria-current={isActive ? "page" : undefined}
                        >
                            {item.label}
                        </button>
                    );
                })}
            </nav>

            <div className="gym-sidebar-bottom">
                <button
                    type="button"
                    className="gym-sidebar-logout"
                    onClick={() => void handleLogout()}
                    disabled={isLoggingOut || navigationDisabled}
                >
                    {isLoggingOut ? "登出中..." : "登出"}
                </button>
                <footer className="gym-sidebar-footer">
                    <p>POWER GYM</p>
                    <span>持續運動，讓改變成為日常</span>
                </footer>
            </div>
        </aside>
    );
}
