import { sessionFetch } from '../../../sessionFetch.js'
import { useEffect, useState } from 'react'

import './AdminSchedule.css'


function AdminSchedule() {

  const [selectedDate, setSelectedDate] =
    useState(
      new Date()
        .toLocaleDateString('en-CA')
    )

  const [schedules, setSchedules] =
    useState([])

  const [loading, setLoading] =
    useState(true)

  const [error, setError] =
    useState('')


  // =========================
  // 固定連續時間軸
  // =========================

  const times = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00'
  ]


  // =========================
  // 取得指定日期全館課表
  // =========================

  const loadSchedules =
    async date => {

      try {

        setLoading(true)
        setError('')


        const response =
          await sessionFetch(
            `/admin/schedules/day?date=${date}`,
            {
              method: 'GET',
              credentials: 'include'
            }
          )


        if (!response.ok) {

          throw new Error(
            '取得全館課表失敗'
          )

        }


        const data =
          await response.json()


        console.log(
          '管理員課表：',
          data
        )


        setSchedules(data)


      } catch (error) {

        console.error(
          '取得管理員課表失敗：',
          error
        )


        setError(
          '無法取得全館教練排課表'
        )


      } finally {

        setLoading(false)

      }

    }


  // =========================
  // 日期變動重新查詢
  // =========================

  useEffect(() => {

    loadSchedules(
      selectedDate
    )

  }, [selectedDate])


  // =========================
  // 前一天 / 後一天
  // =========================

  const changeDate =
    days => {

      const currentDate =
        new Date(
          `${selectedDate}T00:00:00`
        )


      currentDate.setDate(
        currentDate.getDate() + days
      )


      setSelectedDate(
        currentDate
          .toLocaleDateString(
            'en-CA'
          )
      )

    }


  // =========================
  // 今天
  // =========================

  const goToday = () => {

    setSelectedDate(
      new Date()
        .toLocaleDateString(
          'en-CA'
        )
    )

  }


  // =========================
  // 教練清單
  // =========================

  const coaches =
    [
      ...new Map(
        schedules.map(
          schedule => [

            schedule.coachid,

            {
              coachid:
                schedule.coachid,

              coachname:
                schedule.coachname
            }

          ]
        )
      ).values()
    ]


  // =========================
  // 找指定時段 + 指定教練
  // =========================

  const findSchedule =
    (
      time,
      coachid
    ) => {

      return schedules.find(
        schedule =>

          schedule.starttime
            ?.slice(0, 5)
          === time

          &&

          schedule.coachid
          === coachid
      )

    }


  return (

    <div className="admin-schedule">


      {/* =========================
          頁面標題
      ========================= */}

      <h2 className="admin-schedule-title">

        全館教練排課表

      </h2>


      {/* =========================
          主卡片
      ========================= */}

      <div className="admin-schedule-card">


        {/* =========================
            日期工具列
        ========================= */}

        <div className="admin-schedule-toolbar">


          <button
            className="admin-date-button"

            onClick={() =>
              changeDate(-1)
            }
          >

            ← 前一天

          </button>


          <div className="admin-date-box">

            {selectedDate}

          </div>


          <button
            className="admin-date-button"

            onClick={() =>
              changeDate(1)
            }
          >

            後一天 →

          </button>


          <button
            className="admin-today-button"

            onClick={
              goToday
            }
          >

            今天

          </button>

        </div>


        {/* =========================
            Loading
        ========================= */}

        {loading && (

          <div className="admin-message">

            載入中...

          </div>

        )}


        {/* =========================
            Error
        ========================= */}

        {error && (

          <div className="admin-message error">

            {error}

          </div>

        )}


        {/* =========================
            無資料
        ========================= */}

        {
          !loading
          &&
          !error
          &&
          schedules.length === 0
          && (

            <div className="admin-message">

              此日期沒有排課資料

            </div>

          )
        }


        {/* =========================
            課表
        ========================= */}

        {
          !loading
          &&
          !error
          &&
          schedules.length > 0
          && (

            <div className="admin-schedule-table">


              {/* 表頭 */}

              <div
                className="admin-schedule-header"

                style={{
                  gridTemplateColumns:
                    `110px repeat(${coaches.length}, minmax(220px, 1fr))`
                }}
              >


                <div className="time-header">

                  時間

                </div>


                {
                  coaches.map(
                    coach => (

                      <div
                        className="coach-header"

                        key={
                          coach.coachid
                        }
                      >

                        {
                          coach.coachname
                        }

                      </div>

                    )
                  )
                }

              </div>


              {/* =========================
                  每個固定時段
              ========================= */}

              {
                times.map(
                  time => (

                    <div
                      className="admin-schedule-row"

                      key={
                        time
                      }

                      style={{
                        gridTemplateColumns:
                          `110px repeat(${coaches.length}, minmax(220px, 1fr))`
                      }}
                    >


                      {/* 時間 */}

                      <div className="time-cell">

                        {time}

                      </div>


                      {/* 每位教練 */}

                      {
                        coaches.map(
                          coach => {

                            const schedule =
                              findSchedule(
                                time,
                                coach.coachid
                              )


                            return (

                              <div
                                className="schedule-cell"

                                key={
                                  `${time}-${coach.coachid}`
                                }
                              >


                                {
                                  schedule
                                  ? (

                                    schedule.membername
                                    ? (

                                      // =========================
                                      // 已預約
                                      // =========================

                                      <div className="admin-booking-card">


                                        {/* 第一列 */}

                                        <div className="booking-main-line">

                                          <strong className="booking-member">

                                            👤

                                            {
                                              schedule.membername
                                            }

                                          </strong>


                                          <span className="booking-separator">

                                            |

                                          </span>


                                          <span className="booking-course-name">

                                            {
                                              schedule.coursename
                                            }

                                          </span>

                                        </div>


                                        {/* 第二列 */}

                                        <div className="booking-time-line">

                                          🕒

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

                                      </div>

                                    )
                                    : (

                                      // =========================
                                      // 有開放時段但尚未預約
                                      // =========================

                                      <div className="admin-open-card">

                                        🕒 空閒

                                      </div>

                                    )

                                  )
                                  : (

                                    // =========================
                                    // 沒有建立這個時段
                                    // =========================

                                    <div className="admin-no-schedule">

                                      —

                                    </div>

                                  )
                                }

                              </div>

                            )

                          }
                        )
                      }

                    </div>

                  )
                )
              }

            </div>

          )
        }

      </div>

    </div>
  )

}


export default AdminSchedule