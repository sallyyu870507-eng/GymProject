import { Link } from "react-router-dom";
import { toggleTheme } from "../theme.js";
import Brand from "../components/Brand.jsx";

export default function LandingPage() {
  return (
    <div className="public">
      <div className="topbar always"><Brand /><span className="spacer" />
        <button className="btn ghost sm" onClick={toggleTheme} aria-label="切換深淺色">◐</button>
      </div>
      <main className="content narrow">
        <div className="card login">
          <img src="/logo-full.png" alt="POWER GYM 力量健身" />
          <h2>請選擇登入身分</h2>
        </div>
        <div className="choose">
          <Link className="card" to="/login?role=member"><b>會員端</b><span className="hint">課程預約、我的課程</span></Link>
          <Link className="card" to="/login?role=coach"><b>教練端</b><span className="hint">教學課表</span></Link>
          <Link className="card" to="/login?role=admin"><b>管理端</b><span className="hint">全館排課總覽</span></Link>
        </div>
      </main>
    </div>
  );
}
