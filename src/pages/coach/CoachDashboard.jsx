import { useEffect, useState } from 'react'

function CoachDashboard() {

  const [dashboard, setDashboard] = useState(null)

  const [schedules, setSchedules] = useState([])

  const [error, setError] = useState('')


  useEffect(() => {

    const today =
      new Date().toLocaleDateString('en-CA')


    /* ================================
       第一支 API：教練首頁統計
    ================================= */

    fetch(
      `http://localhost:8080/coaches/dashboard?date=${today}`,
      {
        method: 'GET',
        credentials: 'include'
      }
    )

      .then(async response => {

        if (!response.ok) {

          const message =
            await response.text()

          throw new Error(message)

        }

        return response.json()

      })

      .then(data => {

        console.log('教練首頁統計:', data)

        setDashboard(data)

      })

      .catch(error => {

        console.error(
          '取得教練首頁統計失敗:',
          error
        )

        setError(
          '沒有教練權限，請先登入教練帳號'
        )

      })



    /* ================================
       第二支 API：今日已預約課表
    ================================= */

    fetch(
      `http://localhost:8080/coaches/schedules?date=${today}`,
      {
        method: 'GET',
        credentials: 'include'
      }
    )

      .then(async response => {

        if (!response.ok) {

          const message =
            await response.text()

          throw new Error(message)

        }

        return response.json()

      })

      .then(data => {

        console.log(
          '今日課表:',
          data
        )

        setSchedules(data)

      })

      .catch(error => {

        console.error(
          '取得今日課表失敗:',
          error
        )

      })


  }, [])



  /* ================================
     沒有教練權限
  ================================= */

  if (error) {

    return (
      <div className="coach-dashboard">

        <h2>
          無法進入教練頁面
        </h2>

        <p>
          {error}
        </p>

      </div>
    )

  }



  /* ================================
     正常教練頁面
  ================================= */

  return (
    <div className="coach-dashboard">


      {/* 頁面標題 */}

      <h2>
        今日教學課表
      </h2>



      {/* =========================
          上方統計卡片
      ========================== */}

      <div className="dashboard-cards">


        <div className="dashboard-card">

          <p>
            今日課程數
          </p>

          <h3>
            {
              dashboard
                ? dashboard.todayCourseCount
                : 0
            }
          </h3>

        </div>


        <div className="dashboard-card">

          <p>
            今日學員數
          </p>

          <h3>
            {
              dashboard
                ? dashboard.todayStudentCount
                : 0
            }
          </h3>

        </div>


      </div>



      {/* =========================
          下方雙欄區域
      ========================== */}

      <div className="coach-content-grid">


        {/* =========================
            左邊：今日課表
        ========================== */}

        <div className="schedule-section">

          <h3>
            今日課表
          </h3>


          <div className="schedule-list">

            {
              schedules.length === 0
                ? (
                  <p>
                    今天沒有已預約課程
                  </p>
                )
                : (
                  schedules.map(schedule => (

                    <div
                      className="schedule-card"
                      key={schedule.scheduleid}
                    >

                      <div className="schedule-time">

                        <strong>
                          {
                            schedule.starttime.substring(
                              0,
                              5
                            )
                          }
                        </strong>

                        <span>
                          -
                        </span>

                        <strong>
                          {
                            schedule.endtime.substring(
                              0,
                              5
                            )
                          }
                        </strong>

                      </div>


                      <div className="schedule-info">

                        <h4>
                          {schedule.coursename}
                        </h4>

                        <p>
                          學員：
                          {schedule.studentname}
                        </p>

                      </div>

                    </div>

                  ))
                )
            }

          </div>

        </div>



        {/* =========================
            右邊：今日學員
        ========================== */}

        <div className="student-section">

          <h3>
            今日學員
          </h3>


          <table className="student-table">

            <thead>

              <tr>

                <th>
                  學員
                </th>

                <th>
                  時間
                </th>

                <th>
                  課程
                </th>

              </tr>

            </thead>


            <tbody>

              {
                schedules.map(schedule => (

                  <tr
                    key={schedule.scheduleid}
                  >

                    <td>
                      {schedule.studentname}
                    </td>


                    <td>

                      {
                        schedule.starttime.substring(
                          0,
                          5
                        )
                      }

                      {' - '}

                      {
                        schedule.endtime.substring(
                          0,
                          5
                        )
                      }

                    </td>


                    <td>
                      {schedule.coursename}
                    </td>

                  </tr>

                ))
              }

            </tbody>

          </table>


          {
            schedules.length === 0 && (

              <p>
                今天沒有學員
              </p>

            )
          }


        </div>


      </div>


    </div>
  )

}

export default CoachDashboard