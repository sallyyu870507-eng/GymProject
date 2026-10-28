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
  // 現在的角色
  // =========================

  const currentRole =
    loginRole || role


  const menuItems =
    menuByRole[currentRole]
    || menuByRole.member


  // =========================
  // 取得目前登入者
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


        setUserName(
          data.name || ''
        )


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
  // Sidebar 點擊
  // =========================

  const handleClick =
    itemKey => {

      if (onNavigate) {

        onNavigate(
          itemKey
        )

      }

    }


  // =========================
  // 歡迎文字
  // =========================

  const getWelcomeText = () => {

    if (
      currentRole === 'member'
    ) {

      if (userName) {

        return `你好，${userName}會員`

      }

      return '你好，會員'

    }


    if (
      currentRole === 'coach'
    ) {

      if (userName) {

        return `你好，${userName}教練`

      }

      return '你好，教練'

    }


    if (
      currentRole === 'admin'
    ) {

      return '你好，管理員'

    }


    return '你好'

  }


  // =========================
  // 登出
  // =========================

  const handleLogout =
    async () => {

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


  return (

    <aside
      className={
        `sidebar sidebar-${currentRole}`
      }
    >


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
          登入者
      ========================= */}

      <div className="role-area">

        <span className="role-label">

          {getWelcomeText()}

        </span>

      </div>


      {/* =========================
          Menu
      ========================= */}

      <nav className="menu">

        {menuItems.map(
          item => (

            <button

              key={
                item.key
              }

              className={
                activeItem ===
                item.key

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

          )
        )}

      </nav>


      {/* =========================
          Bottom
      ========================= */}

      <div className="sidebar-bottom">


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