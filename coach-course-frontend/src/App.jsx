import { useState } from 'react'
import Sidebar from './components/Sidebar'
import StudentCourses from './components/StudentCourses'
import StudentCoaches from './components/StudentCoaches'
import AdminCoaches from './components/AdminCoaches'
import AdminCourses from './components/AdminCourses'
import { adminTestMode } from './adminTestMode'
import './App.css'

const otherPageTitles = {
  home: '首頁',
  'my-bookings': '我的預約',
  booking: '預約課程',
  members: '會員管理',
  students: '學員清單',
  schedule: '課表',
  attendance: '學員出席',
  care: '續約與關懷',
}

export default function App() {
  const [activePage, setActivePage] = useState('courses')
  const [user, setUser] = useState(null)
  const [loginError, setLoginError] = useState('')
  const currentRole = adminTestMode ? 'admin' : user?.role
  const isAdmin = currentRole === 'admin'
  const isMember = currentRole === 'member'

  const isCourseOrCoachPage =
    activePage === 'courses' || activePage === 'coaches'

  return (
    <div className="cc-layout">
      <Sidebar
        role={currentRole || 'member'}
        activeItem={activePage}
        onNavigate={setActivePage}
        onUserLoaded={setUser}
        onUserError={setLoginError}
      />

      <main className="cc-main">
        {adminTestMode && <p className="cc-admin-test-banner" role="status">管理員測試模式<span>使用真實後端 API，操作會修改實際資料。</span><a href={window.location.pathname}>關閉測試模式</a></p>}
        {!adminTestMode && !user && <p role={loginError ? 'alert' : 'status'}>{loginError || '正在確認登入身分…'}{loginError && <a href="http://localhost:8080/login">前往登入</a>}</p>}
        {isMember && isCourseOrCoachPage && (
          <section className="cc-banner">
            <div className="cc-banner-content">
              <h1>
                找到你的節奏，
                <br />
                練成喜歡的自己。
              </h1>

              <p>
                從第一堂訓練開始，讓專業教練陪你
                <br />
                建立習慣，一步一步靠近目標。
              </p>
            </div>
          </section>
        )}

        {isMember && activePage === 'courses' && <StudentCourses />}

        {isMember && activePage === 'coaches' && <StudentCoaches />}
        {isAdmin && activePage === 'courses' && <AdminCourses />}
        {isAdmin && activePage === 'coaches' && <AdminCoaches />}

        {(adminTestMode || user) && (!isCourseOrCoachPage || (!isAdmin && !isMember)) && (
          <section className="cc-section">
            <h2>{otherPageTitles[activePage] || '學員專區'}</h2>
            <p className="cc-description">
              此頁面尚未接入目前的課程與教練前端。
            </p>
          </section>
        )}
      </main>
    </div>
  )
}
