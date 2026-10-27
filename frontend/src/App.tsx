import { Navigate, Route, Routes } from 'react-router-dom';
import { HOME, RequireRole, useAuth } from './auth/AuthContext';
import { AppShell } from './components/AppShell';
import SignInPage from './pages/SignInPage';
import ManagePage from './pages/admin/ManagePage';
import CoachMembersPage from './pages/coach/CoachMembersPage';
import TrainerPage from './pages/coach/TrainerPage';
import BookingsPage from './pages/student/BookingsPage';
import CoursesPage from './pages/student/CoursesPage';
import InBodyPage from './pages/student/InBodyPage';
import NewBookingPage from './pages/student/NewBookingPage';
import ProfilePage from './pages/student/ProfilePage';
import RemindPage from './pages/student/RemindPage';
import StudentHome from './pages/student/StudentHome';

/**
 * 前端路由刻意不用 /login、/member、/coach、/admin：
 * 這些路徑是後端的（vite.config.ts 會轉送給 Spring Boot）。
 */
export default function App() {
  return (
    <Routes>
      <Route path="/signin" element={<SignInPage />} />

      <Route
        element={
          <RequireRole role="member">
            <AppShell />
          </RequireRole>
        }
      >
        <Route path="/student" element={<StudentHome />} />
        <Route path="/student/remind" element={<RemindPage />} />
        <Route path="/student/profile" element={<ProfilePage />} />
        <Route path="/student/inbody" element={<InBodyPage />} />
        <Route path="/student/courses" element={<CoursesPage />} />
        <Route path="/student/bookings" element={<BookingsPage />} />
        <Route path="/student/bookings/new" element={<NewBookingPage />} />
      </Route>

      <Route
        element={
          <RequireRole role="coach">
            <AppShell />
          </RequireRole>
        }
      >
        <Route path="/trainer" element={<TrainerPage />} />
        <Route path="/trainer/members" element={<CoachMembersPage />} />
      </Route>

      <Route
        element={
          <RequireRole role="admin">
            <AppShell />
          </RequireRole>
        }
      >
        <Route path="/manage" element={<ManagePage />} />
      </Route>

      <Route path="*" element={<HomeRedirect />} />
    </Routes>
  );
}

function HomeRedirect() {
  const { user } = useAuth();
  return <Navigate to={user ? HOME[user.role] : '/signin'} replace />;
}
