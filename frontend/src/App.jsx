import { useEffect, useState } from 'react'
import Sidebar from './components/Sidebar.jsx'
import MemberPage from './MemberPage.jsx'
import { request } from './api.js'

/*
負責決定使用者目前看到的畫面
開啟網站時呼叫api/user確認登入狀態以及顯示登入表單透過POST/login給後端
*/

export default function App() {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const loginErrors = {
    invalid: '帳號或密碼錯誤',
    inactive: '帳號已停用',
    usernameEmpty: '請輸入帳號',
    passwordEmpty: '請輸入密碼',
  }
  //抓使用者
  async function loadUser() {
    setLoading(true)
    setError('')
    try {
      setUser(await request('/api/user'))
    } catch (e) {
      if (e.status !== 401) setError(e.message)
    } finally {
      setLoading(false)
    }
  }
  useEffect(() => {
    loadUser()
  }, []) //空陣列，第一次載入完成執行一次loadUser()
  if (loading)
    return (
      <main className="login-screen">
        <p role="status">正在確認登入狀態…</p>
      </main>
    )
  if (!user)
    return (
      <main className="login-screen">
        <section className="login-card">
          <h1>力量健身</h1>
          <p className="muted">登入會員管理系統</p>
		  		  {/*  &&左側的條件成立，執行右側的動作，意思:
					當「內部狀態有錯誤（error）」或者「網址列傳來了已知的登入錯誤（loginErrors[...]）」時，
					條件成立，進入下一步
					loginErrors是錯誤訊息對照表，會拿key去找中文或是其他可識別的錯誤提示 */}
          {(error ||
            loginErrors[new URLSearchParams(location.search).get('error')]) && (
            <p className="error" role="alert">
			{/* role是無障礙設計 */}
			{/* 這邊決定網頁顯示要的文字，邏輯與上面相符，上面是判斷條件，這邊是決定前端顯示內容
				如果元件error有內容就顯示，如果沒有則用loginErrors找到的對照錯誤提示字詞 */}
              {error ||
                loginErrors[new URLSearchParams(location.search).get('error')]}
            </p>
          )}
          <form method="post" action="/login">
            <label>
              帳號
              <input name="username" autoComplete="username" required />
            </label>
            <label>
              密碼
              <input
                type="password"
                name="password"
                autoComplete="current-password"
                required
              />
            </label>
            <button className="primary" type="submit">
              登入
            </button>
          </form>
          {error && (
            <button className="plain" onClick={loadUser}>
              重新連線
            </button>
          )}
        </section>
      </main>
    )
  const isAdmin = user.role === 'admin'
  return ( 
	/* return打算要渲染到瀏覽器畫面的jsx內容*/
    <div className={`app ${isAdmin ? 'theme-admin' : 'theme-coach'}`}>
      <Sidebar
        user={user}
        activeItem={ //決定進入頁面後第一個選中的頁籤
          isAdmin ? 'members' : user.role === 'coach' ? 'students' : 'home'
        }
      />
      <main className="content">
        {['admin', 'coach'].includes(user.role) ? (
          <MemberPage
            role={user.role}
            onExpired={() => {
              setUser(null)
              setError('登入已過期，請重新登入。')
            }}
          />
        ) : ( //三元運算子，如果不是前面的管理員或教練條件，就會到這邊一般會員的渲染邏輯
          <>
            <h1>會員首頁</h1>
            <p className="muted">此角色的功能目前僅保留靜態版面。</p>
          </>
        )}
      </main>
    </div>
  )
}
