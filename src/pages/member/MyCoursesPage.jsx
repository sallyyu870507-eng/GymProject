import { Link } from "react-router-dom";
import { gymApi } from "../../api/gymApi.js";
import { useAsync } from "../../hooks/useAsync.js";
import DataTable from "../../components/DataTable.jsx";
import { ErrorState, Loading } from "../../components/State.jsx";

export default function MyCoursesPage() {
  const { data, loading, error } = useAsync(() => gymApi.myCourses(), []);
  return (
    <>
      <h1>我的課程</h1>
      <div className="card">
        <h3>已購買課程</h3>
        {loading ? <Loading /> : error ? <ErrorState error={error} /> : (
          <DataTable
            rows={data}
            columns={[
              { label: "課程", key: "coursename" },
              { label: "教練", key: "coachname" },
              { label: "剩餘堂數", key: "remainingsessions" },
            ]} />
        )}
        <p><Link className="btn" to="/member/reserve">前往預約</Link></p>
      </div>
    </>
  );
}
