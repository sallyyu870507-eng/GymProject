import { useEffect, useState } from 'react'

import './CoachDashboard.css'


function CoachDashboard() {

  const [selectedDate, setSelectedDate] =
    useState(
      new Date()
        .toLocaleDateString('en-CA')
    )

  const [dashboard, setDashboard] =
    useState({
      todayCourseCount: 0,
      todayStudentCount: 0
    })

  const [schedules, setSchedules] =
    useState([])

  const [loading, setLoading] =
    useState(true)

  const [error, setError] =
    useState('')


  // =========================
  // 取得教練 Dashboard
  // =========================

  useEffect(() => {

    const loadDashboard =
      fetch(
        `http://localhost:8080/coaches/dashboard?date=${selectedDate}`,
        {
          method: 'GET',
          credentials: 'include'
        }
      )
        .then(response => {

          if (!response.ok) {
            throw new Error(
              '取得統計資料失敗'
            )
          }

          return response.json()
        })


    const loadSchedules =
      fetch(
        `http://localhost:8080/coaches/schedules?date=${selectedDate}`,
        {
          method: 'GET',
          credentials: 'include'
        }
      )
        .then(response => {

          if (!response.ok) {
            throw new Error(
              '取得課表失敗'
            )
          }

          return response.json()
        })


    setLoading(true)
    setError('')


    Promise.all([
      loadDashboard,
      loadSchedules
    ])
      .then(
        ([
          dashboardData,
          scheduleData
        ]) => {

          setDashboard(
            dashboardData
          )

          setSchedules(
            scheduleData
          )

        }
      )
      .catch(error => {

        console.error(
          '取得教練資料失敗：',
          error
        )

        setError(
          '無法取得教練課表資料'
        )

      })
      .finally(() => {

        setLoading(false)

      })

  }, [selectedDate])


  // =========================
  // 今日學員
  // 依照課表整理
  // =========================

  const studentRows =
    schedules.map(
      (schedule, index) => ({
        index:
          index + 1,

        studentname:
          schedule.studentname,

        coursename:
          schedule.coursename,

        starttime:
          schedule.starttime,

        endtime:
          schedule.endtime,

        scheduleid:
          schedule.scheduleid
      })
    )


  return (

    <div className="coach-dashboard">


      {/* =========================
          頁面標題
      ========================= */}

      <h2 className="coach-dashboard-title">

        我的課表

      </h2>


      {/* =========================
          白色主卡片
      ========================= */}

      <div className="coach-dashboard-card">


        {/* =========================
            日期查詢
        ========================= */}

        <div className="coach-date-row">

          <label htmlFor="coach-date">

            查詢日期

          </label>


          <input
            id="coach-date"

            type="date"

            value={
              selectedDate
            }

            onChange={event =>
              setSelectedDate(
                event.target.value
              )
            }
          />

        </div>


        {/* Loading */}

        {loading && (

          <div className="coach-message">

            載入中...

          </div>

        )}


        {/* Error */}

        {error && (

          <div className="coach-message error">

            {error}

          </div>

        )}


        {!loading && !error && (

          <>


            {/* =========================
                上方統計卡片
            ========================= */}

            <div className="dashboard-cards">


              {/* 今日課程數 */}

              <div className="dashboard-card course-count-card">

                <div className="dashboard-icon orange-icon">

                  📅

                </div>


                <div className="dashboard-card-content">

                  <p>
                    今日課程數
                  </p>

                  <div className="dashboard-number-row">

                    <strong>
                      {
                        dashboard.todayCourseCount
                        ?? 0
                      }
                    </strong>

                    <span>
                      堂
                    </span>

                  </div>

                </div>


                <div className="dashboard-watermark">

                  📅

                </div>

              </div>


              {/* 今日學生數 */}

              <div className="dashboard-card student-count-card">

                <div className="dashboard-icon blue-icon">

                  👥

                </div>


                <div className="dashboard-card-content">

                  <p>
                    今日學生數
                  </p>

                  <div className="dashboard-number-row">

                    <strong>
                      {
                        dashboard.todayStudentCount
                        ?? 0
                      }
                    </strong>

                    <span>
                      位
                    </span>

                  </div>

                </div>


                <div className="dashboard-watermark">

                  👥

                </div>

              </div>

            </div>


            {/* =========================
                下方雙欄
            ========================= */}

            <div className="coach-content-grid">


              {/* =========================
                  今日課表
              ========================= */}

              <section className="schedule-section">


                <div className="section-header">

                  <span className="section-icon">

                    📅

                  </span>

                  <h3>

                    今日課表

                  </h3>

                </div>


                {schedules.length === 0 ? (

                  <div className="empty-coach-data">

                    今日尚無預約課程

                  </div>

                ) : (

                  <div className="schedule-list">


                    {schedules.map(
                      schedule => (

                        <div
                          className="schedule-card"

                          key={
                            schedule.scheduleid
                          }
                        >


                          <div className="schedule-left">


                            <div className="schedule-time">

                              {
                                schedule.starttime
                                  ?.slice(0, 5)
                              }

                              {' - '}

                              {
                                schedule.endtime
                                  ?.slice(0, 5)
                              }

                            </div>


                            <span className="schedule-status">

                              已預約

                            </span>

                          </div>


                          <div className="schedule-divider" />


                          <div className="schedule-info">

                            <h4>

                              {
                                schedule.coursename
                              }

                            </h4>


                            <p>

                              <span>
                                👤
                              </span>

                              學員：

                              {
                                schedule.studentname
                              }

                            </p>

                          </div>


                          <div className="schedule-arrow">

                            ›

                          </div>

                        </div>

                      )
                    )}

                  </div>

                )}

              </section>


              {/* =========================
                  今日學員
              ========================= */}

              <section className="student-section">


                <div className="section-header">

                  <span className="section-icon">

                    👥

                  </span>

                  <h3>

                    今日學員

                  </h3>

                </div>


                {studentRows.length === 0 ? (

                  <div className="empty-coach-data">

                    今日尚無學員

                  </div>

                ) : (

                  <div className="student-table-wrapper">

                    <table className="student-table">


                      <thead>

                        <tr>

                          <th className="student-number-column">
                            #
                          </th>

                          <th>
                            學員姓名
                          </th>

                          <th>
                            課程名稱
                          </th>

                          <th>
                            上課時段
                          </th>

                        </tr>

                      </thead>


                      <tbody>

                        {studentRows.map(
                          student => (

                            <tr
                              key={
                                student.scheduleid
                              }
                            >


                              <td className="student-number">

                                {
                                  student.index
                                }

                              </td>


                              <td>

                                <div className="student-name-cell">

                                  <div className="student-avatar">

                                    👤

                                  </div>

                                  <strong>

                                    {
                                      student.studentname
                                    }

                                  </strong>

                                </div>

                              </td>


                              <td>

                                {
                                  student.coursename
                                }

                              </td>


                              <td>

                                {
                                  student.starttime
                                    ?.slice(0, 5)
                                }

                                {' - '}

                                {
                                  student.endtime
                                    ?.slice(0, 5)
                                }

                              </td>

                            </tr>

                          )
                        )}

                      </tbody>

                    </table>

                  </div>

                )}

              </section>

            </div>

          </>

        )}

      </div>

    </div>
  )
}


export default CoachDashboard