import Sidebar from './components/Sidebar'
import AdminSchedule from './pages/admin/AdminSchedule'
import './App.css'

function App() {

  return (
    <div className='app'>

      <Sidebar />

      <main className='main-content'>

        <header className='topbar'>

          <h1>
            全館教練排課表
          </h1>

          <p>
            你好，管理員
          </p>

        </header>


        <div className="page-container">

          <AdminSchedule />

        </div>

      </main>

    </div>
  )

}

export default App