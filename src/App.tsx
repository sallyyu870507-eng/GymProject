import { Navigate, Route, Routes } from 'react-router-dom';
import { AppShell } from './components/AppShell';
import TrainerPage from './pages/coach/TrainerPage';
import StudentHome from './pages/student/StudentHome';


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
