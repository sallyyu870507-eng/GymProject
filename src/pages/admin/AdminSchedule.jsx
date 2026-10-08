import { useEffect, useState } from 'react'

function AdminSchedule() {

  const [selectedDate, setSelectedDate] = useState(
    new Date().toLocaleDateString('en-CA')
  )

  const [schedules, setSchedules] = useState([])

  const [coaches, setCoaches] = useState([])

  const [error, setError] = useState('')


  useEffect(() => {

    setError('')


    /* ================================
       第一支 API：取得全部教練
    ================================= */

    fetch(
      'http://localhost:8080/admin/schedules/coaches',
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
          '全部教練:',
          data
        )

        setCoaches(data)

      })

      .catch(error => {

        console.error(
          '取得教練清單失敗:',
          error
        )

        setError(error.message)

      })



    /* ================================
       第二支 API：指定日期全館課表
    ================================= */

    fetch(
      `http://localhost:8080/admin/schedules/day?date=${selectedDate}`,
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
          '管理員全館課表:',
          data
        )

        setSchedules(data)

      })

      .catch(error => {

        console.error(
          '取得管理員課表失敗:',
          error
        )

        setError(error.message)

      })

  }, [selectedDate])



  /* ================================
     日期切換
  ================================= */

  function changeDate(days) {

    const date =
      new Date(`${selectedDate}T00:00:00`)

    date.setDate(
      date.getDate() + days
    )

    setSelectedDate(
      date.toLocaleDateString('en-CA')
    )

  }



  /* ================================
     回到今天
  ================================= */

  function goToday() {

    setSelectedDate(
      new Date().toLocaleDateString('en-CA')
    )

  }



  /* ================================
     固定顯示的時段
  ================================= */

  const timeSlots = [
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
    '19:00'
  ]



  /* ================================
     錯誤畫面
  ================================= */

  if (error) {

    return (
      <div className="admin-schedule">

        <h2>
          無法取得管理員課表
        </h2>

        <p>
          {error}
        </p>

      </div>
    )

  }



  /* ================================
     正常畫面
  ================================= */

  return (
    <div className="admin-schedule">


      {/* 頁面標題 */}

      <h2>
        全館教練排課表
      </h2>



      {/* =========================
          日期切換工具列
      ========================== */}

      <div className="admin-schedule-toolbar">


        <button
          onClick={() => changeDate(-1)}
        >
          ← 前一天
        </button>


        <div className="admin-date-box">

          {selectedDate}

        </div>


        <button
          onClick={() => changeDate(1)}
        >
          後一天 →
        </button>


        <button
          onClick={goToday}
        >
          今天
        </button>


      </div>



      {/* =========================
          全館教練課表
      ========================== */}

      <div className="admin-schedule-table">


        {/* =========================
            表頭
        ========================== */}

        <div
          className="admin-schedule-header"
          style={{
            gridTemplateColumns:
              `110px repeat(${coaches.length}, minmax(180px, 1fr))`
          }}
        >


          <div className="time-header">
            時間
          </div>


          {
            coaches.map(coach => (

              <div
                className="coach-header"
                key={coach.coachid}
              >

                {coach.coachname}

              </div>

            ))
          }


        </div>



        {/* =========================
            每一個時間列
        ========================== */}

        {
          timeSlots.map(time => (

            <div
              className="admin-schedule-row"
              key={time}
              style={{
                gridTemplateColumns:
                  `110px repeat(${coaches.length}, minmax(180px, 1fr))`
              }}
            >


              {/* 左邊時間 */}

              <div className="time-cell">

                {time}

              </div>



              {/* 每位教練 */}

              {
                coaches.map(coach => {


                  const schedule =
                    schedules.find(item =>

                      item.coachid === coach.coachid

                      &&

                      item.starttime.substring(0, 5)
                        === time

                    )


                  return (

                    <div
                      className="schedule-cell"
                      key={
                        `${coach.coachid}-${time}`
                      }
                    >


                      {
                        schedule
                          ? (

                            <div
                              className={
                                schedule.status === 'booked'
                                  ? 'admin-booking-card booked'
                                  : schedule.status === 'available'
                                    ? 'admin-booking-card available'
                                    : 'admin-booking-card unavailable'
                              }
                            >


                              <strong>

                                {
                                  schedule.membername
                                    ? schedule.membername
                                    : '尚未預約'
                                }

                              </strong>


                              <span>

                                {
                                  schedule.coursename
                                    ? schedule.coursename
                                    : '可預約時段'
                                }

                              </span>


                              <small>

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

                              </small>


                            </div>

                          )

                          : (

                            <div className="empty-slot">
                            </div>

                          )
                      }


                    </div>

                  )

                })
              }


            </div>

          ))
        }


      </div>


    </div>
  )

}

export default AdminSchedule