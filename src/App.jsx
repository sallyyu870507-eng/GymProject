import { Navigate, Route, Routes } from "react-router-dom";
import Layout from "./components/Layout.jsx";
import RequireRole from "./auth/RequireRole.jsx";
import { useAuth } from "./auth/AuthContext.jsx";
import LoginPage from "./pages/LoginPage.jsx";
import ReservePage from "./pages/member/ReservePage.jsx";
import MyCoursesPage from "./pages/member/MyCoursesPage.jsx";
import CoachSchedulePage from "./pages/coach/CoachSchedulePage.jsx";
import AdminSchedulePage from "./pages/admin/AdminSchedulePage.jsx";

// 各身分的側邊欄選單：新增頁面 = 寫好 pages/ 檔案，在這裡加一行 link 與一個 Route
const MEMBER_LINKS = [
  { to: "/member/reserve", icon: "🗓️", label: "課程預約" },
  { to: "/member/courses", icon: "🏋️", label: "我的課程" },
];
const COACH_LINKS = [{ to: "/coach/schedule", icon: "📋", label: "教學課表" }];
const ADMIN_LINKS = [{ to: "/admin/schedule", icon: "📋", label: "全館排課表" }];

const guarded = (role, label, links) => (
  <RequireRole role={role}>
    <Layout roleLabel={label} links={links} />
  </RequireRole>
);

// 首頁：已登入進自己的畫面，未登入去登入頁
function Home() {
  const { auth } = useAuth();
  return <Navigate to={auth?.role ? `/${auth.role}` : "/login"} replace />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/login" element={<LoginPage />} />

      <Route path="/member" element={guarded("member", "會員端", MEMBER_LINKS)}>
        <Route index element={<Navigate to="reserve" replace />} />
        <Route path="reserve" element={<ReservePage />} />
        <Route path="courses" element={<MyCoursesPage />} />
      </Route>

      <Route path="/coach" element={guarded("coach", "教練端", COACH_LINKS)}>
        <Route index element={<Navigate to="schedule" replace />} />
        <Route path="schedule" element={<CoachSchedulePage />} />
      </Route>

      <Route path="/admin" element={guarded("admin", "管理端", ADMIN_LINKS)}>
        <Route index element={<Navigate to="schedule" replace />} />
        <Route path="schedule" element={<AdminSchedulePage />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
