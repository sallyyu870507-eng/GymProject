import logo from '../assets/power-gym-logo.jpg'

function Sidebar(){
	return (
		<aside className="sidebar">
		
				
		<div className="logo-area">
		<img src={logo} alt="Power Gym Logo" className="logo"/>
		</div>
		
		<nav className='menu'>
		
		<button className='menu-item'>
		首頁
		</button>
		<button className='menu-item active'>
		預約課程
		</button>
		<button className='menu-item'>
		我的課程
		</button>
		<button className='menu-item'>
		會員資料
		</button>
		
		</nav>
		
		<div className='sidebar-footer'>
		<p>持續運動</p>
		<span>讓改變成為日常</span>
		</div>
		
		</aside>
		
	)
}

export default Sidebar