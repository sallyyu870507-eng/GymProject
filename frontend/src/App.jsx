import { useEffect, useState } from 'react'
import { Link, Navigate, Outlet, Route, Routes, useBeforeUnload, useBlocker, useLocation, useNavigate } from 'react-router'
import Sidebar from './components/Sidebar.jsx'
import MemberPage from './MemberPage.jsx'
import { request } from './api.js'
import CatalogPage from './features/catalog/CatalogPage.jsx'
import AdminSchedule from './features/booking/admin/AdminSchedule.jsx'
import CoachDashboard from './features/booking/coach/CoachDashboard.jsx'
import BookingCourse from './features/booking/member/BookingCourse.jsx'
import MyBookings from './features/booking/member/MyBookings.jsx'
import AttendancePage from './pages/attendance/AttendancePage'
import RenewalWorkbenchPage from './pages/renewal/RenewalWorkbenchPage'
import RenewalOverviewPage from './pages/renewal/RenewalOverviewPage'
import RenewalFollowupCreatePage from './pages/renewal/RenewalFollowupCreatePage'
import RenewalFollowupEditPage from './pages/renewal/RenewalFollowupEditPage'
import RenewalCreatePage from './pages/renewal/RenewalCreatePage'
import './features/team-base.css'

const destinations = { home: '/', members: '/members', students: '/students', courses: '/courses', coaches: '/coaches', schedule: '/schedule', attendance: '/attendance', care: '/renewal', booking: '/book-course', 'my-bookings': '/my-bookings' }
const loginErrors = { invalid: '帳號或密碼錯誤', inactive: '帳號已停用', usernameEmpty: '請輸入帳號', passwordEmpty: '請輸入密碼' }

function Shell({ user }) {
  const location = useLocation()
  const navigate = useNavigate()
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false)
  const [navigationLocked, setNavigationLocked] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  useEffect(() => {
    if (!mobileOpen) return
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    document.querySelector('#gym-navigation .menu-item')?.focus()
    const closeOnEscape = event => { if (event.key === 'Escape') setMobileOpen(false) }
    window.addEventListener('keydown', closeOnEscape)
    return () => {
      document.body.style.overflow = previousOverflow
      window.removeEventListener('keydown', closeOnEscape)
      document.querySelector('.mobile-bar button')?.focus()
    }
  }, [mobileOpen])
  const blocker = useBlocker(({ currentLocation, nextLocation }) =>
    (hasUnsavedChanges || navigationLocked) && currentLocation.pathname !== nextLocation.pathname)
  useEffect(() => {
    if (blocker.state !== 'blocked') return
    if (!navigationLocked && window.confirm('尚有未儲存的內容，確定離開？')) {
      setHasUnsavedChanges(false)
      blocker.proceed()
    } else blocker.reset()
  }, [blocker, navigationLocked])
  useBeforeUnload(event => {
    if (hasUnsavedChanges || navigationLocked) { event.preventDefault(); event.returnValue = '' }
  })
  const activeItem = location.pathname.startsWith('/renewal') ? 'care' : Object.keys(destinations).find(key => destinations[key] === location.pathname) || 'home'
  return <div className="integrated-app">
    <header className="mobile-bar"><strong>POWER GYM</strong><button onClick={() => setMobileOpen(!mobileOpen)} aria-expanded={mobileOpen} aria-controls="gym-navigation">選單</button></header>
    {mobileOpen && <button className="sidebar-overlay" aria-label="關閉選單" onClick={() => setMobileOpen(false)} />}
    <div id="gym-navigation" className={`navigation-panel ${mobileOpen ? 'open' : ''}`}>
      <Sidebar user={user} role={user.role} activeItem={activeItem} navigationDisabled={navigationLocked} onNavigate={key => { navigate(destinations[key]); setMobileOpen(false) }} onBeforeLogout={() => !navigationLocked && (!hasUnsavedChanges || window.confirm('尚有未儲存的內容，確定登出？'))} />
    </div>
    <main className="integrated-content"><Outlet context={{ userName: user.name || '', setHasUnsavedChanges, setNavigationLocked }} /></main>
  </div>
}

function Home({ user }) {
  const items = user.role === 'member' ? ['courses', 'coaches', 'my-bookings', 'booking'] : user.role === 'coach' ? ['students', 'schedule', 'attendance', 'care'] : ['members', 'coaches', 'courses', 'schedule']
  const labels = { courses: '課程總覽', coaches: '教練介紹', 'my-bookings': '我的預約', booking: '預約課程', students: '學員清單', schedule: '課表', attendance: '學員出席', care: '續約與關懷', members: '會員管理' }
  return <section className="home-page"><h1>你好，{user.name || '歡迎回來'}</h1><p>從選單或下方功能開始。</p><div className="home-links">{items.map(key => <Link key={key} to={destinations[key]}>{labels[key]}</Link>)}</div></section>
}

function Access({ role, allowed, children }) {
  return allowed.includes(role) ? children : <section className="home-page"><h1>此功能不適用目前身分</h1><Link to="/">返回首頁</Link></section>
}

export default function App() {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  async function loadUser() {
    setLoading(true)
    setError('')
    try { setUser(await request('/api/user')) }
    catch (e) { setUser(null); if (e.status !== 401) setError(e.message) }
    finally { setLoading(false) }
  }
  useEffect(() => { loadUser() }, [])
  useEffect(() => {
    const expire = () => { setUser(null); setError('登入已過期，請重新登入。') }
    window.addEventListener('gym:session-expired', expire)
    return () => window.removeEventListener('gym:session-expired', expire)
  }, [])
  if (loading) return <div className="member-feature"><main className="login-screen"><p role="status">正在確認登入狀態…</p></main></div>
  if (!user) return <div className="member-feature"><main className="login-screen"><section className="login-card">
    <h1>力量健身</h1><p className="muted">登入健身管理系統</p>
    {(error || loginErrors[new URLSearchParams(location.search).get('error')]) && <p className="error" role="alert">{error || loginErrors[new URLSearchParams(location.search).get('error')]}</p>}
    <form method="post" action="/login"><label>帳號<input name="username" autoComplete="username" required /></label><label>密碼<input type="password" name="password" autoComplete="current-password" required /></label><button className="primary" type="submit">登入</button></form>
    {error && <button className="plain" onClick={loadUser}>重新連線</button>}
  </section></main></div>
  const guard = (allowed, page) => <Access role={user.role} allowed={allowed}>{page}</Access>
  const members = <div className={`member-feature theme-${user.role} feature-padding`}><MemberPage role={user.role} onExpired={() => { setUser(null); setError('登入已過期，請重新登入。') }} /></div>
  const team = page => guard(['coach'], <div className="team-feature">{page}</div>)
  return <Routes><Route element={<Shell user={user} />}>
    <Route index element={<Home user={user} />} />
    {['admin', 'coach', 'member', 'login', 'login.html'].map(path => <Route key={path} path={path} element={<Navigate to={user.role === 'admin' ? '/members' : '/'} replace />} />)}
    <Route path="members" element={guard(['admin'], members)} />
    <Route path="students" element={guard(['coach'], members)} />
    <Route path="courses" element={guard(['member', 'admin'], <CatalogPage role={user.role} kind="courses" />)} />
    <Route path="coaches" element={guard(['member', 'admin'], <CatalogPage role={user.role} kind="coaches" />)} />
    <Route path="schedule" element={guard(['admin', 'coach'], user.role === 'admin' ? <div className="admin-schedule-feature feature-padding"><AdminSchedule /></div> : <div className="coach-schedule-feature feature-padding"><CoachDashboard /></div>)} />
    <Route path="book-course" element={guard(['member'], <div className="booking-course-feature feature-padding"><BookingCourse /></div>)} />
    <Route path="my-bookings" element={guard(['member'], <div className="my-bookings-feature feature-padding"><MyBookings /></div>)} />
    <Route path="attendance" element={team(<AttendancePage />)} />
    <Route path="renewal" element={team(<RenewalWorkbenchPage />)} />
    <Route path="renewal/:memberCourseId" element={team(<RenewalOverviewPage />)} />
    <Route path="renewal/:memberCourseId/followups/new" element={team(<RenewalFollowupCreatePage />)} />
    <Route path="renewal/:memberCourseId/followups/:followupId/edit" element={team(<RenewalFollowupEditPage />)} />
    <Route path="renewal/:memberCourseId/renewals/new" element={team(<RenewalCreatePage />)} />
    <Route path="*" element={<section className="home-page"><h1>找不到頁面</h1><Link to="/">返回首頁</Link></section>} />
  </Route></Routes>
}
