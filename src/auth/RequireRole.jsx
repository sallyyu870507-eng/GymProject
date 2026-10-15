import { Navigate } from "react-router-dom";
import { useAuth } from "./AuthContext.jsx";

export default function RequireRole({ role, children }) {
  const { auth } = useAuth();
  if (auth?.role !== role) return <Navigate to="/login" replace />;
  return children;
}
