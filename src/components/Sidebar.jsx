import { useEffect, useState } from 'react'

import logo from '../assets/logo.png'
import './Sidebar.css'


// =========================
// 不同角色的選單
// =========================

const menuByRole = {

  member: [
    { key: 'home', label: '首頁' },
    { key: 'courses', label: '課程總覽' },
    { key: 'coaches', label: '教練介紹' },
    { key: 'my-bookings', label: '我的預約' },
    { key: 'booking', label: '預約課程' }
  ],

  coach: [
    { key: 'home', label: '首頁' },
    { key: 'students', label: '學員清單' },
    { key: 'schedule', label: '我的課表' },
    { key: 'attendance', label: '學員出席' },
    { key: 'care', label: '續約與關懷' }
  ],

  admin: [
    { key: 'members', label: '會員管理' },
    { key: 'coaches', label: '教練管理' },
    { key: 'courses', label: '課程管理' },
    { key: 'schedule', label: '全館課表總覽' }
  ]

}


function Sidebar({
  role = 'member',
  activeItem = 'home',
  onNavigate
}) {

  // =========================
  // 登入者資料
  // =========================

  const [userName, setUserName] =
    useState('')

  const [loginRole, setLoginRole] =
    useState(role)

  const [isLoggingOut, setIsLoggingOut] =
    useState(false)


  // =========================
  // Sidebar 要顯示哪個角色選單
  // =========================

  const currentRole =
    loginRole || role

  const menuItems =
    menuByRole[currentRole]
    || menuByRole.member


  // =========================
  // 取得目前登入者
  // GET /api/user
  // =========================

  useEffect(() => {

    fetch(
      'http://localhost:8080/api/user',
      {
        method: 'GET',

        credentials: 'include'
      }
    )

      .then(response => {

        if (!response.ok) {

          throw new Error(
            '無法取得登入者資料'
          )

        }

        return response.json()

      })

      .then(data => {

        console.log(
          '目前登入者：',
          data
        )


        // 取得登入者姓名
        setUserName(
          data.name || ''
        )


        // 取得真正登入角色
        if (data.role) {

          setLoginRole(
            data.role
          )

        }

      })

      .catch(error => {

        console.error(
          '取得登入者資料失敗：',
          error
        )

      })

  }, [])


  // =========================
  // 點選 Sidebar Menu
  // =========================

  const handleClick = itemKey => {

    if (onNavigate) {

      onNavigate(
        itemKey
      )

    }

  }


  // =========================
  // 顯示歡迎文字
  // =========================

  const getWelcomeText = () => {

    // 會員
    if (currentRole === 'member') {

      if (userName) {

        return `你好，${userName}會員`

      }

      return '你好，會員'

    }


    // 教練
    if (currentRole === 'coach') {

      if (userName) {

        return `你好，${userName}教練`

      }

      return '你好，教練'

    }


    // 管理員
    if (currentRole === 'admin') {

      return '你好，管理員'

    }


    return '你好'

  }


  // =========================
  // 登出
  // POST /logout
  // =========================

  const handleLogout = async () => {

    // 防止連續點擊
    if (isLoggingOut) {

      return

    }


    try {

      setIsLoggingOut(true)


      const response =
        await fetch(
          'http://localhost:8080/logout',
          {
            method: 'POST',

            credentials: 'include'
          }
        )


      if (!response.ok) {

        throw new Error(
          '登出失敗'
        )

      }


      // =====================
      // 登出成功
      // 回登入頁面
      // =====================

      window.location.href =
        'http://localhost:8080/login'


    } catch (error) {

      console.error(
        '登出失敗：',
        error
      )


      alert(
        '登出失敗，請稍後再試'
      )


    } finally {

      setIsLoggingOut(false)

    }

  }


  // =========================
  // 畫面
  // =========================

  return (

    <aside className="sidebar">


      {/* =========================
          Logo
      ========================= */}

      <div className="logo-area">

        <img
          src={logo}
          alt="Power Gym Logo"
          className="logo"
        />
		
		<div className="brand-name">
		  力量健身
		</div>

      </div>


      {/* =========================
          登入者資訊
      ========================= */}

      <div className="role-area">

        <span className="role-label">

          {getWelcomeText()}

        </span>

      </div>


      {/* =========================
          Sidebar Menu
      ========================= */}

      <nav className="menu">

        {menuItems.map(item => (

          <button

            key={item.key}

            className={
              activeItem === item.key

                ? 'menu-item active'

                : 'menu-item'
            }

            onClick={() =>
              handleClick(
                item.key
              )
            }
          >

            {item.label}

          </button>

        ))}

      </nav>


      {/* =========================
          Sidebar 底部
      ========================= */}

      <div className="sidebar-bottom">


        {/* 登出 */}

        <button

          className="logout-button"

          onClick={
            handleLogout
          }

          disabled={
            isLoggingOut
          }
        >

          {
            isLoggingOut
              ? '登出中...'
              : '登出'
          }

        </button>


        {/* Footer */}

        <div className="sidebar-footer">

          <p>
            POWER GYM
          </p>

          <span>

            持續運動，讓改變成為日常

          </span>

        </div>


      </div>


    </aside>

  )

}


export default Sidebar