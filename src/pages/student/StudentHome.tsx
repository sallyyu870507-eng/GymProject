import { Link } from 'react-router-dom';
import { AvatarPlaceholder, MetaList, MiniStats, Placeholder } from '../../components/skeleton';
import { Card } from '../../components/ui';

/** 學員首頁：依 Figma 線框稿（下一堂課 + 2×2 卡片） */
export default function StudentHome() {
  return (
    <div className="page">
      <h1 className="hello">你好，學員</h1>

      <section className="card next-bar">
        <h2>下一堂課</h2>
        <div className="next-info">
          <div className="next-when">—</div>
          <div>課程・教室</div>
          <div>教練：—</div>
        </div>
        <Link to="/student/remind" className="btn btn-lg">
          查看課程
        </Link>
      </section>

      <div className="grid-2">
        <Card title="會員管理" footer={<Link to="/student/profile" className="btn">查看資料</Link>}>
          <div className="member-summary">
            <AvatarPlaceholder />
            <MetaList fields={['姓名', '會員編號', '手機', '生日', '狀態']} />
          </div>
        </Card>

        <Card title="INBODY 分析" footer={<Link to="/student/inbody" className="btn">查看分析</Link>}>
          <MiniStats labels={['體重 kg', '肌肉量 kg', '體脂率 %', '體脂肪重 kg']} />
          <Placeholder label="體重與肌肉量趨勢圖" height={170} />
        </Card>

        <Card title="課程管理" footer={<Link to="/student/courses" className="btn">查看課程</Link>}>
          <p className="muted">已購課程與剩餘堂數</p>
        </Card>

        <Card title="出席紀錄" footer={<Link to="/student/bookings" className="btn">查看預約</Link>}>
          <MiniStats labels={['近 12 週到館', '已完成課程', '已取消']} />
          <Placeholder label="每週到館次數長條圖" height={160} />
        </Card>
      </div>
    </div>
  );
}
