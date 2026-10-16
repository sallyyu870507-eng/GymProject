import logo from '../assets/power-gym-logo.jpg'
import './Sidebar.css'

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
	  { key: 'care', label: '續約與關懷' },
	],
	admin: [
	  { key: 'members', label: '會員管理' },
	  { key: 'coaches', label: '教練管理' },
	  { key: 'courses', label: '課程管理' },
	  { key: 'schedule', label: '全館課表總覽' }
	]
}

	const roleName ={
		member:'會員',
		coach:'教練',
		admin:'管理員'
	}


	function Sidebar({
		role = 'member',
		activeItem = 'home',
		onNavigate
	}){
		const menuItems = menuByRole[role] || menuByRole.member
		const handleClick =(itemKey)=>{
			if(onNavigate){
				onNavigate(itemKey)
			}
		}
		
		return(
			<aside className='sidebar'>
			<div className='logo-area'>
			
			<img
			src={logo}
			alt='Power Gym Logo'
			className='logo'
		    />
			</div>
			
			<div className='role-area'>
			<span className='role-label'>
			{roleName[role]||'會員'}
			</span>
			</div>
			
			<nav className='menu'>
			{menuItems.map((item)=>(
				<button
				key={item.key}
				className={
					activeItem == item.key
					?'menu-item active'
					:'menu-item' 
				}
				onClick={()=>handleClick(item.key)}>
				
				{item.label}
				</button>
			))}
			</nav>
			
			<div className='sidebar-footer'>
			<p>POWER GYM</p>
			
			<span>
			持續運動，讓改變成為日常
			</span>
			</div>
			</aside>
		)
	}

export default Sidebar