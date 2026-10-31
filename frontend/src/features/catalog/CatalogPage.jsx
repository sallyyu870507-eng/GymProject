import StudentCourses from './StudentCourses'
import StudentCoaches from './StudentCoaches'
import AdminCourses from './AdminCourses'
import AdminCoaches from './AdminCoaches'
import './Catalog.css'

export default function CatalogPage({ role, kind }) {
  const courses = kind === 'courses'
  return <div className="catalog-feature cc-main">
    {role === 'member' && <><div className="cc-page-heading"><h2>{courses ? '課程總覽' : '教練介紹'}</h2><p className="cc-description">{courses ? '不論剛開始，或想更進一步，找到適合你的訓練。' : '不同專長，一樣用心。找到陪你一起進步的夥伴。'}</p></div><section className="cc-banner"><div className="cc-banner-content"><h1>找到你的節奏，<br />練成喜歡的自己。</h1><p>從第一堂訓練開始，讓專業教練陪你<br />建立習慣，一步一步靠近目標。</p></div></section></>}
    {role === 'admin' ? courses ? <AdminCourses /> : <AdminCoaches /> : courses ? <StudentCourses /> : <StudentCoaches />}
  </div>
}
