import { useEffect, useState } from "react";
import { Outlet, useLocation, useNavigate } from "react-router";

import Sidebar, { type SidebarMenuKey } from "../sidebar/Sidebar";
import "./AppLayout.css";

const implementedDestinations: Partial<Record<SidebarMenuKey, string>> = {
    attendance: "/attendance",
    care: "/renewal",
};
const availableItems: SidebarMenuKey[] = ["attendance", "care"];

export default function AppLayout() {
    const [userName, setUserName] = useState("");
    const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);
    const [navigationLocked, setNavigationLocked] = useState(false);
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
    const location = useLocation();
    const navigate = useNavigate();

    const activeItem: SidebarMenuKey =
        location.pathname === "/attendance"
            ? "attendance"
            : location.pathname.startsWith("/renewal")
                ? "care"
                : "home";

    function handleNavigate(item: SidebarMenuKey) {
        const destination = implementedDestinations[item];

        if (destination) {
            if (navigationLocked) return false;
            if (hasUnsavedChanges && !window.confirm("尚有未儲存的內容，確定離開？")) return false;
            setHasUnsavedChanges(false);
            navigate(destination);
            return true;
        }
        return false;
    }

    function navigateFromSidebar(item: SidebarMenuKey) {
        if (handleNavigate(item)) setMobileMenuOpen(false);
    }

    useEffect(() => {
        if (!mobileMenuOpen) return;
        const previousOverflow = document.body.style.overflow;
        document.body.style.overflow = "hidden";
        const closeOnEscape = (event: KeyboardEvent) => {
            if (event.key === "Escape") setMobileMenuOpen(false);
        };
        window.addEventListener("keydown", closeOnEscape);
        return () => {
            document.body.style.overflow = previousOverflow;
            window.removeEventListener("keydown", closeOnEscape);
        };
    }, [mobileMenuOpen]);

    return (
        <div className="gym-app-layout">
            <header className="gym-mobile-bar">
                <strong>POWER GYM</strong>
                <button
                    type="button"
                    className="gym-mobile-menu-toggle"
                    aria-label="開啟導覽選單"
                    aria-expanded={mobileMenuOpen}
                    aria-controls="gym-sidebar"
                    onClick={() => setMobileMenuOpen(true)}
                >
                    <span /><span /><span />
                </button>
            </header>
            {mobileMenuOpen && <button
                type="button"
                className="gym-sidebar-overlay"
                aria-label="關閉導覽選單"
                onClick={() => setMobileMenuOpen(false)}
            />}
            <Sidebar
                isOpen={mobileMenuOpen}
                onClose={() => setMobileMenuOpen(false)}
                activeItem={activeItem}
                onNavigate={navigateFromSidebar}
                availableItems={availableItems}
                navigationDisabled={navigationLocked}
                onUserNameChange={setUserName}
            />
            <div className="gym-app-content">
                <Outlet context={{ userName, setHasUnsavedChanges, setNavigationLocked }} />
            </div>
        </div>
    );
}
