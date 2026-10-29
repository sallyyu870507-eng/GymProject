import { Navigate, Route, Routes } from 'react-router-dom';
import { AppShell } from './components/AppShell';
import TrainerPage from './pages/coach/TrainerPage';
import StudentHome from './pages/student/StudentHome';

/**
 * Dashboard 版面骨架：只有學員端首頁（/student）與教練端首頁（/trainer）。
 * 側邊欄的其他項目由其他組員製作；頁面還沒加入前，點了會回到各自的首頁。
 * 登入與權限由其他組員負責，這裡不做檢查。
 */
export default function App() {
  return (
    <Routes>
      <Route element={<AppShell />}>
        <Route path="/student" element={<StudentHome />} />
        <Route path="/trainer" element={<TrainerPage />} />
      </Route>

      <Route path="/student/*" element={<Navigate to="/student" replace />} />
      <Route path="/trainer/*" element={<Navigate to="/trainer" replace />} />
      <Route path="*" element={<Navigate to="/student" replace />} />
    </Routes>
  );
}
