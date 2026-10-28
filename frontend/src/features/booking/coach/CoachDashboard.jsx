import { sessionFetch } from '../../../sessionFetch.js'
import { useEffect, useMemo, useState } from 'react'
import './CoachDashboard.css'


function CoachDashboard() {

  // =====================================================
  // 日期
  // =====================================================

  const todayString =
    new Date().toLocaleDateString('en-CA')

  const [selectedDate, setSelectedDate] =
    useState(todayString)


  // =====================================================
  // Dashboard
  // =====================================================

  const [dashboard, setDashboard] =
    useState({
      courseCount: 0,
      studentCount: 0
    })


  // =====================================================
  // 課表
  // =====================================================

  const [schedules, setSchedules] =
    useState([])

  const [loading, setLoading] =
    useState(false)


  // =====================================================
  // Modal
  // =====================================================

  const [showBookingModal, setShowBookingModal] =
    useState(false)

  const [selectedBooking, setSelectedBooking] =
    useState(null)

  const [isCancelling, setIsCancelling] =
    useState(false)


  // =====================================================
  // 時間格式
  // =====================================================

  const formatTime = (time) => {

    if (!time) {
      return ''
    }

    return String(time)
      .substring(0, 5)
  }


  // =====================================================
  // 日期格式
  // =====================================================

  const formatDate = (dateString) => {

    if (!dateString) {
      return ''
    }

    const date =
      new Date(
        `${dateString}T00:00:00`
      )

    return date.toLocaleDateString(
      'zh-TW'
    )
  }


  // =====================================================
  // 今天以前不能取消
  // =====================================================

  const canCancelBooking = () => {

    if (!selectedDate) {
      return false
    }

    const today =
      new Date()
        .toLocaleDateString('en-CA')

    return selectedDate >= today
  }


  // =====================================================
  // Dashboard API
  // =====================================================

  const loadDashboard = async () => {

    const response = await sessionFetch(
      `/coaches/dashboard?date=${selectedDate}`,
      {
        method: 'GET',
        credentials: 'include'
      }
    )


    if (!response.ok) {

      throw new Error(
        '取得教練統計資料失敗'
      )
    }


    const data =
      await response.json()


    setDashboard({

      courseCount:
        data.todayCourseCount ??
        data.courseCount ??
        0,

      studentCount:
        data.todayStudentCount ??
        data.studentCount ??
        0

    })
  }


  // =====================================================
  // Schedule API
  // =====================================================

  const loadSchedules = async () => {

    const response = await sessionFetch(
      `/coaches/schedules?date=${selectedDate}`,
      {
        method: 'GET',
        credentials: 'include'
      }
    )


    if (!response.ok) {

      throw new Error(
        '取得教練課表失敗'
      )
    }


    const data =
      await response.json()


    console.log(
      '教練課表：',
      data
    )


    setSchedules(
      Array.isArray(data)
        ? data
        : []
    )
  }


  // =====================================================
  // 載入整頁
  // =====================================================

  const loadPage = async () => {

    try {

      setLoading(true)


      await Promise.all([
        loadDashboard(),
        loadSchedules()
      ])


    } catch (error) {

      console.error(
        '載入教練頁面失敗：',
        error
      )


    } finally {

      setLoading(false)

    }
  }


  useEffect(() => {

    loadPage()

  }, [selectedDate])


  // =====================================================
  // 今日學生
  // =====================================================

  const studentRows =
    useMemo(() => {

      return schedules.map(
        (schedule, index) => ({

          id:
            schedule.bookingid ??
            schedule.scheduleid ??
            index,

          membername:
            schedule.studentname ??
            schedule.membername ??
            '—',

          coursename:
            schedule.coursename ??
            '—',

          time:
            `${formatTime(schedule.starttime)} - ${formatTime(schedule.endtime)}`

        })
      )

    }, [schedules])


  // =====================================================
  // 打開 Modal
  // =====================================================

  const openBookingModal =
    (schedule) => {

      setSelectedBooking(schedule)

      setShowBookingModal(true)
    }


  // =====================================================
  // 關閉 Modal
  // =====================================================

  const closeBookingModal = () => {

    if (isCancelling) {
      return
    }

    setShowBookingModal(false)

    setSelectedBooking(null)
  }


  // =====================================================
  // 教練代取消
  // =====================================================

  const handleCoachCancel =
    async () => {

      if (
        !selectedBooking ||
        isCancelling
      ) {
        return
      }


      if (!canCancelBooking()) {

        alert(
          '今天以前的預約無法取消'
        )

        return
      }


      const bookingid =
        selectedBooking.bookingid


      if (!bookingid) {

        alert(
          '找不到這筆預約的 bookingid'
        )

        return
      }


      const confirmCancel =
        window.confirm(
          '確定要取消這位學員的預約嗎？'
        )


      if (!confirmCancel) {
        return
      }


      try {

        setIsCancelling(true)


        const response = await sessionFetch(
          `/coaches/${bookingid}/coach-cancel`,
          {
            method: 'PUT',
            credentials: 'include'
          }
        )


        const result =
          await response.text()


        if (!response.ok) {

          throw new Error(
            result ||
            '取消預約失敗'
          )
        }


        alert(
          result ||
          '教練代取消成功'
        )


        setShowBookingModal(false)

        setSelectedBooking(null)


        await loadPage()


      } catch (error) {

        console.error(
          '教練取消預約失敗：',
          error
        )


        alert(
          `取消失敗：${error.message}`
        )


      } finally {

        setIsCancelling(false)

      }
    }


  return (

    <div className="coach-dashboard-page">


      {/* =================================================
          頁面標題
      ================================================= */}

      <h2 className="coach-page-title">

        我的課表

      </h2>


      {/* =================================================
          主卡
      ================================================= */}

      <section className="coach-dashboard-card">


        {/* =================================================
            日期
        ================================================= */}

        <div className="coach-date-toolbar">

          <label>

            查詢日期

          </label>


          <input
            type="date"

            value={selectedDate}

            onChange={
              event =>
                setSelectedDate(
                  event.target.value
                )
            }
          />

        </div>


        {/* =================================================
            統計
        ================================================= */}

        <div className="coach-stat-grid">


          <div className="coach-stat-card course-stat-card">

            <div className="coach-stat-icon orange">

              🗓️

            </div>


            <div className="coach-stat-content">

              <span>

                今日課程數

              </span>


              <div>

                <strong>

                  {
                    dashboard.courseCount
                  }

                </strong>

                <small>

                  堂

                </small>

              </div>

            </div>


            <div className="coach-stat-decoration">

              ▦

            </div>

          </div>


          <div className="coach-stat-card student-stat-card">

            <div className="coach-stat-icon blue">

              👥

            </div>


            <div className="coach-stat-content">

              <span>

                今日學生數

              </span>


              <div>

                <strong>

                  {
                    dashboard.studentCount
                  }

                </strong>

                <small>

                  位

                </small>

              </div>

            </div>


            <div className="coach-stat-decoration">

              👥

            </div>

          </div>

        </div>


        {/* =================================================
            內容區
        ================================================= */}

        <div className="coach-content-grid">


          {/* =================================================
              今日課表
          ================================================= */}

          <section className="coach-panel">


            <div className="coach-panel-title">

              <span>

                🗓️

              </span>

              <h3>

                今日課表

              </h3>

            </div>


            <div className="coach-schedule-list">


              {loading && (

                <div className="coach-empty">

                  載入中...

                </div>

              )}


              {!loading &&
                schedules.length === 0 && (

                  <div className="coach-empty">

                    這一天目前沒有已預約課程

                  </div>

                )}


              {!loading &&
                schedules.map(
                  schedule => (

                    <div
                      key={
                        schedule.bookingid
                      }

                      className="coach-schedule-card"
                    >


                      {/* =========================
                          時間區
                      ========================= */}

                      <div className="schedule-time-column">

                        <strong>

                          {
                            formatTime(
                              schedule.starttime
                            )
                          }

                          {' - '}

                          {
                            formatTime(
                              schedule.endtime
                            )
                          }

                        </strong>


                        <span>

                          已預約

                        </span>

                      </div>


                      {/* =========================
                          分隔線
                      ========================= */}

                      <div className="schedule-divider" />


                      {/* =========================
                          課程＋學員
                      ========================= */}

                      <div className="schedule-info-column">

                        <h4>

                          {
                            schedule.coursename ??
                            '—'
                          }

                        </h4>


                        <p>

                          👤 學員：

                          {
                            schedule.studentname ??
                            schedule.membername ??
                            '—'
                          }

                        </p>

                      </div>


                      {/* =========================
                          查看預約
                      ========================= */}

                      <div className="schedule-action-column">

                        <button
                          type="button"

                          className="schedule-detail-button"

                          onClick={() =>
                            openBookingModal(
                              schedule
                            )
                          }
                        >

                          查看預約

                        </button>

                      </div>

                    </div>

                  )
                )}

            </div>

          </section>


          {/* =================================================
              今日學生
          ================================================= */}

          <section className="coach-panel">


            <div className="coach-panel-title">

              <span>

                👥

              </span>

              <h3>

                今日學員

              </h3>

            </div>


            <div className="coach-student-table-wrapper">

              <table className="coach-student-table">

                <thead>

                  <tr>

                    <th>#</th>

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

                  {
                    studentRows.map(
                      (student, index) => (

                        <tr key={student.id}>

                          <td>

                            {index + 1}

                          </td>


                          <td>

                            <div className="student-name-cell">

                              <span className="student-avatar">

                                👤

                              </span>


                              <strong>

                                {
                                  student.membername
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
                              student.time
                            }

                          </td>

                        </tr>

                      )
                    )
                  }

                </tbody>

              </table>

            </div>

          </section>

        </div>

      </section>


      {/* =====================================================
          預約資訊 Modal
      ===================================================== */}

      {showBookingModal &&
        selectedBooking && (

          <div
            className="booking-detail-overlay"

            onMouseDown={
              event => {

                if (
                  event.target ===
                  event.currentTarget
                ) {

                  closeBookingModal()

                }

              }
            }
          >

            <div className="booking-detail-modal">


              {/* Header */}

              <div className="booking-detail-header">

                <div>

                  <h3>

                    預約資訊

                  </h3>


                  <p>

                    查看本次課程資訊，
                    或協助學員取消預約。

                  </p>

                </div>


                <button
                  type="button"

                  className="booking-detail-close"

                  disabled={
                    isCancelling
                  }

                  onClick={
                    closeBookingModal
                  }
                >

                  ×

                </button>

              </div>


              {/* Status */}

              <div className="booking-detail-status">

                <span className="status-dot" />

                已預約

              </div>


              {/* Content */}

              <div className="booking-detail-content">


                <div className="booking-detail-row">

                  <div className="booking-detail-icon">

                    👤

                  </div>

                  <span>

                    學員

                  </span>

                  <strong>

                    {
                      selectedBooking.studentname ??
                      selectedBooking.membername ??
                      '—'
                    }

                  </strong>

                </div>


                <div className="booking-detail-row">

                  <div className="booking-detail-icon">

                    🏋

                  </div>

                  <span>

                    課程

                  </span>

                  <strong>

                    {
                      selectedBooking.coursename ??
                      '—'
                    }

                  </strong>

                </div>


                <div className="booking-detail-row">

                  <div className="booking-detail-icon">

                    📅

                  </div>

                  <span>

                    日期

                  </span>

                  <strong>

                    {
                      formatDate(
                        selectedDate
                      )
                    }

                  </strong>

                </div>


                <div className="booking-detail-row">

                  <div className="booking-detail-icon">

                    ◷

                  </div>

                  <span>

                    時段

                  </span>

                  <strong>

                    {
                      formatTime(
                        selectedBooking.starttime
                      )
                    }

                    {' - '}

                    {
                      formatTime(
                        selectedBooking.endtime
                      )
                    }

                  </strong>

                </div>

              </div>


              {/* Warning */}

              <div
                className={
                  canCancelBooking()
                    ? 'booking-detail-warning'
                    : 'booking-detail-warning disabled-warning'
                }
              >

                <span>

                  !

                </span>


                <p>

                  {
                    canCancelBooking()
                      ? '取消後，此筆預約將不會繼續顯示在您的已預約課表中。'
                      : '今天以前的預約已無法取消。'
                  }

                </p>

              </div>


              {/* Actions */}

              <div className="booking-detail-actions">

                <button
                  type="button"

                  className="booking-detail-back-btn"

                  disabled={
                    isCancelling
                  }

                  onClick={
                    closeBookingModal
                  }
                >

                  關閉

                </button>


                <button
                  type="button"

                  className="booking-detail-cancel-btn"

                  disabled={
                    isCancelling ||
                    !canCancelBooking()
                  }

                  onClick={
                    handleCoachCancel
                  }
                >

                  {
                    isCancelling
                      ? '取消中...'

                      : !canCancelBooking()
                        ? '已無法取消'

                        : '取消預約'
                  }

                </button>

              </div>

            </div>

          </div>

        )}

    </div>

  )
}


export default CoachDashboard