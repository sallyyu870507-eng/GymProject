import { useEffect, useMemo, useState } from 'react'

import './AdminSchedule.css'


function AdminSchedule() {

  // =====================================================
  // 今天
  // =====================================================

  const getTodayString = () => {

    return new Date()
      .toLocaleDateString('en-CA')
  }


  // =====================================================
  // 日期 state
  // =====================================================

  const [selectedDate, setSelectedDate] =
    useState(getTodayString())

  const [schedules, setSchedules] =
    useState([])

  const [loading, setLoading] =
    useState(false)


  // =====================================================
  // 固定時間軸
  // 09:00 ～ 21:00
  // =====================================================

  const timeSlots = useMemo(() => {

    const times = []

    for (
      let hour = 9;
      hour <= 21;
      hour++
    ) {

      times.push(
        `${String(hour).padStart(2, '0')}:00`
      )

    }

    return times

  }, [])


  // =====================================================
  // 取得管理員課表
  // =====================================================

  const loadSchedules = async () => {

    try {

      setLoading(true)


      const response = await fetch(

        `http://localhost:8080/api/admin/schedules/day?date=${selectedDate}`,

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
        '管理員全館課表：',
        data
      )


      setSchedules(

        Array.isArray(data)
          ? data
          : []

      )


    } catch (error) {

      console.error(
        '取得管理員課表失敗：',
        error
      )


      setSchedules([])


    } finally {

      setLoading(false)

    }

  }


  // =====================================================
  // 日期改變重新查詢
  // =====================================================

  useEffect(() => {

    loadSchedules()

  }, [selectedDate])


  // =====================================================
  // 日期加減
  // =====================================================

  const changeDate =
    (days) => {

      const current =
        new Date(
          `${selectedDate}T00:00:00`
        )


      current.setDate(
        current.getDate() + days
      )


      setSelectedDate(
        current.toLocaleDateString(
          'en-CA'
        )
      )

    }


  // =====================================================
  // 今天
  // =====================================================

  const goToday = () => {

    setSelectedDate(
      getTodayString()
    )

  }


  // =====================================================
  // 格式時間
  // =====================================================

  const formatTime =
    (time) => {

      if (!time) {

        return ''

      }

      return String(time)
        .substring(0, 5)
    }


  // =====================================================
  // 取得全部教練
  // =====================================================

  const coaches = useMemo(() => {

    const map =
      new Map()


    schedules.forEach(
      schedule => {

        if (
          schedule.coachid &&
          !map.has(
            schedule.coachid
          )
        ) {

          map.set(
            schedule.coachid,
            {

              coachid:
                schedule.coachid,

              coachname:
                schedule.coachname ??
                `教練 ${schedule.coachid}`

            }
          )

        }

      }
    )


    return Array.from(
      map.values()
    )

  }, [schedules])


  // =====================================================
  // 找某教練某時段
  // =====================================================

  const findSchedule =
    (coachid, time) => {

      return schedules.find(
        schedule => {

          return (

            schedule.coachid ===
              coachid &&

            formatTime(
              schedule.starttime
            ) === time

          )

        }
      )

    }


  // =====================================================
  // 顯示時段結束時間
  // =====================================================

  const getEndTime =
    (startTime) => {

      const hour =
        Number(
          startTime.substring(
            0,
            2
          )
        )


      return `${String(hour + 1).padStart(2, '0')}:00`

    }


  return (

    <div className="admin-schedule-page">


      {/* =================================================
          頁面標題
      ================================================= */}

      <h2 className="admin-page-title">

        全館教練排課表

      </h2>


      {/* =================================================
          白色主卡片
      ================================================= */}

      <section className="admin-schedule-card">


        {/* =================================================
            日期工具列
        ================================================= */}

        <div className="admin-date-toolbar">


          {/* 前一天 */}

          <button
            type="button"
            className="admin-date-button"

            onClick={() =>
              changeDate(-1)
            }
          >

            ← 前一天

          </button>


          {/* =================================================
              可點選日曆的日期
          ================================================= */}

          <input
            type="date"

            className="admin-date-picker"

            value={
              selectedDate
            }

            onChange={
              event =>
                setSelectedDate(
                  event.target.value
                )
            }
          />


          {/* 後一天 */}

          <button
            type="button"
            className="admin-date-button"

            onClick={() =>
              changeDate(1)
            }
          >

            後一天 →

          </button>


          {/* 今天 */}

          <button
            type="button"
            className="admin-today-button"

            onClick={
              goToday
            }
          >

            今天

          </button>

        </div>


        {/* =================================================
            Loading
        ================================================= */}

        {loading && (

          <div className="admin-schedule-loading">

            課表載入中...

          </div>

        )}


        {/* =================================================
            沒有教練 / 沒課表
        ================================================= */}

        {!loading &&
          coaches.length === 0 && (

            <div className="admin-schedule-empty">

              這一天目前沒有排課資料

            </div>

          )}


        {/* =================================================
            課表
        ================================================= */}

        {!loading &&
          coaches.length > 0 && (

            <div className="admin-table-wrapper">


              {/* =================================================
                  Header
              ================================================= */}

              <div
                className="admin-schedule-header"

                style={{

                  gridTemplateColumns:

                    `100px repeat(${coaches.length}, minmax(190px, 1fr))`

                }}
              >


                <div className="admin-time-header">

                  時間

                </div>


                {
                  coaches.map(
                    coach => (

                      <div
                        key={
                          coach.coachid
                        }

                        className="admin-coach-header"
                      >

                        {
                          coach.coachname
                        }

                      </div>

                    )
                  )
                }

              </div>


              {/* =================================================
                  Rows
              ================================================= */}

              {
                timeSlots.map(
                  time => (

                    <div
                      key={time}

                      className="admin-schedule-row"

                      style={{

                        gridTemplateColumns:

                          `100px repeat(${coaches.length}, minmax(190px, 1fr))`

                      }}
                    >


                      {/* 時間 */}

                      <div className="admin-time-cell">

                        {time}

                      </div>


                      {/* 教練 */}

                      {
                        coaches.map(
                          coach => {

                            const schedule =
                              findSchedule(
                                coach.coachid,
                                time
                              )


                            // =========================
                            // 根本沒有排這個時段
                            // =========================

                            if (!schedule) {

                              return (

                                <div
                                  key={
                                    coach.coachid
                                  }

                                  className="admin-schedule-cell"
                                >

                                  <span className="admin-no-schedule">

                                    —

                                  </span>

                                </div>

                              )

                            }


                            // =========================
                            // 已被預約
                            // =========================

                            if (
                              schedule.status ===
                                'booked' ||
                              schedule.membername
                            ) {

                              return (

                                <div
                                  key={
                                    coach.coachid
                                  }

                                  className="admin-schedule-cell"
                                >

                                  <div className="admin-booking-card">


                                    <div className="booking-main-line">

                                      <span>
                                        👤
                                      </span>


                                      <strong>

                                        {
                                          schedule.membername ??
                                          '會員'
                                        }

                                      </strong>


                                      <span className="booking-separator">

                                        |

                                      </span>


                                      <span>

                                        {
                                          schedule.coursename ??
                                          '課程'
                                        }

                                      </span>

                                    </div>


                                    <div className="booking-time-line">

                                      <span>
                                        ◷
                                      </span>


                                      <span>

                                        {
                                          formatTime(
                                            schedule.starttime
                                          )
                                        }

                                        {' - '}

                                        {
                                          formatTime(
                                            schedule.endtime
                                          ) ||
                                          getEndTime(
                                            time
                                          )
                                        }

                                      </span>

                                    </div>

                                  </div>

                                </div>

                              )

                            }


                            // =========================
                            // 有排課但目前沒人預約
                            // =========================

                            return (

                              <div
                                key={
                                  coach.coachid
                                }

                                className="admin-schedule-cell"
                              >

                                <div className="admin-open-card">

                                  空閒

                                </div>

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

          )}

      </section>

    </div>

  )
}


export default AdminSchedule