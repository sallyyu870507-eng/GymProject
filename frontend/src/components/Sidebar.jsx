import { sessionFetch } from '../sessionFetch.js'
import { useState } from 'react'
import logo from '../assets/logo.png'
import './Sidebar.css'

// Fangyu's role menus and markup are the common navigation design.
const menuByRole = {
  member: [{ key: 'home', label: '首頁' }, { key: 'courses', label: '課程總覽' }, { key: 'coaches', label: '教練介紹' }, { key: 'my-bookings', label: '我的預約' }, { key: 'booking', label: '預約課程' }],
  coach: [{ key: 'home', label: '首頁' }, { key: 'students', label: '學員清單' }, { key: 'schedule', label: '我的課表' }, { key: 'attendance', label: '學員出席' }, { key: 'care', label: '續約與關懷' }],
  admin: [{ key: 'members', label: '會員管理' }, { key: 'coaches', label: '教練管理' }, { key: 'courses', label: '課程管理' }, { key: 'schedule', label: '全館課表總覽' }],
}

export default function Sidebar({ user, role = 'member', activeItem = 'home', onNavigate, navigationDisabled, onBeforeLogout }) {
  const [isLoggingOut, setIsLoggingOut] = useState(false)
  const [error, setError] = useState('')
  const roleName = { member: '會員', coach: '教練', admin: '管理員' }[role] || ''
  async function handleLogout() {
    if (isLoggingOut || (onBeforeLogout && !onBeforeLogout())) return
    setIsLoggingOut(true)
    setError('')
    try {
      const response = await sessionFetch('/logout', { method: 'POST', credentials: 'include' })
      if (!response.ok) throw new Error('登出失敗，請稍後再試。')
      window.location.replace('/')
    } catch (failure) { setError(failure.message); setIsLoggingOut(false) }
  }
  return <aside className={`sidebar sidebar-${role}`}>
    <div className="logo-area"><img src={logo} alt="Power Gym Logo" className="logo" /><div className="brand-name">力量健身</div></div>
    <div className="role-area"><span className="role-label">你好，{role === 'admin' ? '' : user?.name || ''}{roleName}</span></div>
    <nav className="menu" aria-label="主要選單">{(menuByRole[role] || []).map(item => <button type="button" key={item.key} className={activeItem === item.key ? 'menu-item active' : 'menu-item'} aria-current={activeItem === item.key ? 'page' : undefined} disabled={navigationDisabled} onClick={() => onNavigate(item.key)}>{item.label}</button>)}</nav>
    <div className="sidebar-bottom">{error && <p role="alert">{error}</p>}<button className="logout-button" onClick={handleLogout} disabled={isLoggingOut || navigationDisabled}>{isLoggingOut ? '登出中...' : '登出'}</button><div className="sidebar-footer"><p>POWER GYM</p><span>持續運動，讓改變成為日常</span></div></div>
  </aside>
}
