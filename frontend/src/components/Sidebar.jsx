import { useState } from 'react'
import logo from '../assets/logo.png'
import './Sidebar.css'

const menuByRole = {
  member: [
    { key: 'home', label: '首頁' },
    { key: 'courses', label: '課程總覽' },
    { key: 'coaches', label: '教練介紹' },
    { key: 'my-bookings', label: '我的預約' },
    { key: 'booking', label: '預約課程' },
  ],
  coach: [
    { key: 'home', label: '首頁' },
    { key: 'students', label: '學員清單' },
    { key: 'schedule', label: '我的課表' },
    { key: 'attendance', label: '學員出席' },
    { key: 'care', label: '續約與關懷' },
  ],
  admin: [
    { key: 'members', label: '會員管理' },
    { key: 'coaches', label: '教練管理' },
    { key: 'courses', label: '課程管理' },
    { key: 'schedule', label: '全館課表總覽' },
  ],
}

export default function Sidebar({ user, activeItem }) {
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const roleName = { admin: '管理員', coach: '教練', member: '會員' }[user.role]
  async function logout() {
    setBusy(true)
    setError('')
    try {
      const response = await fetch('/logout', {
        method: 'POST',
        credentials: 'include',
      })
      if (!response.ok) throw new Error('登出失敗，請稍後再試。')
      window.location.assign('/')
    } catch (e) {
      setError(e.message)
      setBusy(false)
    }
  }
  return (
    <aside className="sidebar">
      <div className="logo-area">
        <img src={logo} alt="Power Gym Logo" className="logo" />
        <div className="brand-name">力量健身</div>
      </div>
      <div className="role-area">
        <span className="role-label">
          你好，{user.name || ''}
          {roleName}
        </span>
      </div>
      <nav className="menu" aria-label="主要選單">
        {(menuByRole[user.role] || []).map((item) => (
          <button
            type="button"
            key={item.key}
            aria-current={item.key === activeItem ? 'page' : undefined} /* 無障礙設計 */
            className={`menu-item ${item.key === activeItem ? 'active' : 'static-item'}`}
            title={
              item.key === activeItem ? item.label : '靜態按鈕，功能尚未實作'
            }
          >
            {item.label}
          </button>
        ))}
      </nav>
      <div className="sidebar-bottom">
        {error && (
          <p role="alert" className="error">
            {error}
          </p>
        )}
        <button className="logout-button" disabled={busy} onClick={logout}>
          {busy ? '登出中…' : '登出'}
        </button>
        <div className="sidebar-footer">
          <p>POWER GYM</p>
          <span>持續運動，讓改變成為日常</span>
        </div>
      </div>
    </aside>
  )
}
