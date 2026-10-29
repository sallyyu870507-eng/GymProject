
import { useEffect, useMemo, useState } from 'react'
import Calendar from 'react-calendar'

import 'react-calendar/dist/Calendar.css'
import './CoachDashboard.css'

function CoachDashboard() {

  // =====================================================
  // 日期工具
  // =====================================================

  const getLocalDateString = date => {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  const todayString = getLocalDateString(new Date())

  const getTodayStart = () => {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    return today
  }

  // =====================================================
  // State
  // =====================================================

  const [selectedDate, setSelectedDate] = useState(todayString)

  const [dashboard, setDashboard] = useState({
    courseCount: 0,
    studentCount: 0
  })

  const [schedules, setSchedules] = useState([])
  const [loading, setLoading] = useState(false)

  // 查看預約
  const [showBookingModal, setShowBookingModal] = useState(false)
  const [selectedBooking, setSelectedBooking] = useState(null)
  const [isCancelling, setIsCancelling] = useState(false)

  // 修改預約
  const [showEditModal, setShowEditModal] = useState(false)
  const [availableDates, setAvailableDates] = useState([])
  const [editSelectedDate, setEditSelectedDate] = useState(null)
  const [scheduleOptions, setScheduleOptions] = useState([])
  const [selectedScheduleId, setSelectedScheduleId] = useState(null)
  const [loadingEditDates, setLoadingEditDates] = useState(false)
  const [loadingEditSlots, setLoadingEditSlots] = useState(false)
  const [isRescheduling, setIsRescheduling] = useState(false)

  // =====================================================
  // 格式化
  // =====================================================

  const formatTime = time => {
    if (!time) return ''
    return String(time).substring(0, 5)
  }

  const formatDate = dateString => {
    if (!dateString) return ''

    const date = new Date(`${dateString}T00:00:00`)
    return date.toLocaleDateString('zh-TW')
  }

  // =====================================================
  // 判斷能否修改或取消
  // 課程開始時間必須晚於現在
  // =====================================================

  const canManageBooking = booking => {
    if (!booking || !selectedDate || !booking.starttime) {
      return false
    }

    const startTime = String(booking.starttime).substring(0, 8)
    const classStart = new Date(`${selectedDate}T${startTime}`)

    return classStart > new Date()
  }

  // =====================================================
  // 日期切換
  // =====================================================

  const goPreviousDay = () => {
    const date = new Date(`${selectedDate}T00:00:00`)
    date.setDate(date.getDate() - 1)
    setSelectedDate(getLocalDateString(date))
  }

  const goNextDay = () => {
    const date = new Date(`${selectedDate}T00:00:00`)
    date.setDate(date.getDate() + 1)
    setSelectedDate(getLocalDateString(date))
  }

  const goToday = () => {
    setSelectedDate(todayString)
  }

  // =====================================================
  // 1. Dashboard API
  // GET /api/coach/dashboard
  // =====================================================

  const loadDashboard = async () => {
    const response = await fetch(
      `http://localhost:8080/api/coach/dashboard?date=${selectedDate}`,
      {
        method: 'GET',
        credentials: 'include'
      }
    )

    if (!response.ok) {
      const message = await response.text()
      throw new Error(message || '取得教練統計資料失敗')
    }

    const data = await response.json()

    setDashboard({
      courseCount: data.todayCourseCount ?? data.courseCount ?? 0,
      studentCount: data.todayStudentCount ?? data.studentCount ?? 0
    })
  }

  // =====================================================
  // 2. 課表 API
  // GET /api/coach/schedules
  // =====================================================

  const loadSchedules = async () => {
    const response = await fetch(
      `http://localhost:8080/api/coach/schedules?date=${selectedDate}`,
      {
        method: 'GET',
        credentials: 'include'
      }
    )

    if (!response.ok) {
      const message = await response.text()
      throw new Error(message || '取得教練課表失敗')
    }

    const data = await response.json()
    setSchedules(Array.isArray(data) ? data : [])
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
      console.error('載入教練頁面失敗：', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadPage()
  }, [selectedDate])

  // =====================================================
  // 學員列表
  // =====================================================

  const studentRows = useMemo(() => {
    return schedules.map((schedule, index) => ({
      id: schedule.bookingid ?? schedule.scheduleid ?? index,
      membername: schedule.studentname ?? schedule.membername ?? '—',
      coursename: schedule.coursename ?? '—',
      time: `${formatTime(schedule.starttime)} - ${formatTime(schedule.endtime)}`
    }))
  }, [schedules])

  // =====================================================
  // 查看預約視窗
  // =====================================================

  const openBookingModal = schedule => {
    setSelectedBooking(schedule)
    setShowBookingModal(true)
  }

  const closeBookingModal = () => {
    if (isCancelling || loadingEditDates) return

    setShowBookingModal(false)
    setSelectedBooking(null)
  }

  // =====================================================
  // 3. 教練取消預約
  //
  // 修改：
  // PUT → POST
  //
  // POST /api/coach/bookings/{bookingid}/cancel
  // =====================================================

  const handleCoachCancel = async () => {
    if (!selectedBooking || isCancelling) return

    if (!canManageBooking(selectedBooking)) {
      alert('課程已開始，無法取消預約')
      return
    }

    const bookingid = selectedBooking.bookingid

    if (!bookingid) {
      alert('找不到 bookingid')
      return
    }

    const confirmCancel = window.confirm(
      '確定要取消這位學員的預約嗎？'
    )

    if (!confirmCancel) return

    try {
      setIsCancelling(true)

      const response = await fetch(
        `http://localhost:8080/api/coach/bookings/${bookingid}/cancel`,
        {
          method: 'POST',
          credentials: 'include'
        }
      )

      const result = await response.text()

      if (!response.ok) {
        throw new Error(result || '取消預約失敗')
      }

      alert(result || '教練代取消成功')

      setShowBookingModal(false)
      setSelectedBooking(null)

      await loadPage()

    } catch (error) {
      console.error('教練取消預約失敗：', error)
      alert(`取消失敗：${error.message}`)
    } finally {
      setIsCancelling(false)
    }
  }

  // =====================================================
  // 4. 開啟修改預約
  // GET /api/coach/bookings/{bookingid}/available-dates
  // =====================================================

  const openEditBooking = async () => {
    if (!selectedBooking) return

    if (!canManageBooking(selectedBooking)) {
      alert('課程已開始，無法修改預約')
      return
    }

    const bookingid = selectedBooking.bookingid

    if (!bookingid) {
      alert('找不到 bookingid')
      return
    }

    try {
      setLoadingEditDates(true)

      setAvailableDates([])
      setScheduleOptions([])
      setEditSelectedDate(null)
      setSelectedScheduleId(null)

      const response = await fetch(
        `http://localhost:8080/api/coach/bookings/${bookingid}/available-dates`,
        {
          method: 'GET',
          credentials: 'include'
        }
      )

      const raw = await response.text()

      if (!response.ok) {
        throw new Error(raw || '取得可修改日期失敗')
      }

      const data = raw ? JSON.parse(raw) : []

      setAvailableDates(Array.isArray(data) ? data : [])
      setShowBookingModal(false)
      setShowEditModal(true)

    } catch (error) {
      console.error('取得可修改日期失敗：', error)
      alert(error.message || '取得可修改日期失敗')
    } finally {
      setLoadingEditDates(false)
    }
  }

  // =====================================================
  // 關閉修改視窗
  // =====================================================

  const closeEditModal = () => {
    if (isRescheduling) return

    setShowEditModal(false)
    setAvailableDates([])
    setScheduleOptions([])
    setEditSelectedDate(null)
    setSelectedScheduleId(null)
    setSelectedBooking(null)
  }

  // =====================================================
  // 5. 查修改時段
  // GET /api/coach/bookings/{bookingid}/schedules
  // =====================================================

  const loadEditScheduleOptions = async date => {
    if (!selectedBooking || !date) return

    const bookingid = selectedBooking.bookingid
    const dateString = getLocalDateString(date)

    try {
      setLoadingEditSlots(true)
      setScheduleOptions([])
      setSelectedScheduleId(null)

      const response = await fetch(
        `http://localhost:8080/api/coach/bookings/${bookingid}/schedules?date=${dateString}`,
        {
          method: 'GET',
          credentials: 'include'
        }
      )

      const raw = await response.text()

      if (!response.ok) {
        throw new Error(raw || '取得可修改時段失敗')
      }

      const data = raw ? JSON.parse(raw) : []

      setScheduleOptions(Array.isArray(data) ? data : [])

    } catch (error) {
      console.error('取得修改時段失敗：', error)
      alert(error.message || '取得可修改時段失敗')
    } finally {
      setLoadingEditSlots(false)
    }
  }

  // =====================================================
  // 修改日期
  // =====================================================

  const handleEditDateChange = date => {
    setEditSelectedDate(date)
    setSelectedScheduleId(null)
    loadEditScheduleOptions(date)
  }

  // =====================================================
  // 6. 確認修改
  //
  // 修改：
  // PUT + JSON → POST + Query Parameter
  //
  // POST /api/coach/bookings/{bookingid}/reschedule
  // ?newScheduleid=1234
  // =====================================================

  const confirmReschedule = async () => {
    if (
      !selectedBooking ||
      !editSelectedDate ||
      selectedScheduleId === null ||
      isRescheduling
    ) {
      return
    }

    const bookingid = selectedBooking.bookingid
    const newDateString = getLocalDateString(editSelectedDate)

    try {
      setIsRescheduling(true)

      const response = await fetch(
        `http://localhost:8080/api/coach/bookings/${bookingid}/reschedule?newScheduleid=${selectedScheduleId}`,
        {
          method: 'POST',
          credentials: 'include'
        }
      )

      const result = await response.text()

      if (!response.ok) {
        throw new Error(result || '修改預約失敗')
      }

      alert(result || '教練修改預約日期時間成功')

      setShowEditModal(false)
      setSelectedBooking(null)
      setAvailableDates([])
      setScheduleOptions([])
      setEditSelectedDate(null)
      setSelectedScheduleId(null)

      setSelectedDate(newDateString)

    } catch (error) {
      console.error('修改預約失敗：', error)
      alert(error.message || '修改預約失敗')
    } finally {
      setIsRescheduling(false)
    }
  }

  // =====================================================
  // JSX 畫面
  // =====================================================

  return (
    <div className="coach-dashboard-page">

      <h2 className="coach-page-title">
        我的課表
      </h2>

      <section className="coach-dashboard-card">

        {/* 日期工具列 */}

        <div className="coach-date-toolbar">

          <button
            type="button"
            className="coach-date-button"
            onClick={goPreviousDay}
          >
            ← 前一天
          </button>

          <input
            type="date"
            className="coach-date-picker"
            value={selectedDate}
            onChange={event => setSelectedDate(event.target.value)}
          />

          <button
            type="button"
            className="coach-date-button"
            onClick={goNextDay}
          >
            後一天 →
          </button>

          <button
            type="button"
            className="coach-today-button"
            onClick={goToday}
          >
            今天
          </button>

        </div>

        {/* 統計卡 */}

        <div className="coach-stat-grid">

          <div className="coach-stat-card course-stat-card">

            <div className="coach-stat-icon orange">
              🗓️
            </div>

            <div className="coach-stat-content">
              <span>今日課程數</span>

              <div>
                <strong>{dashboard.courseCount}</strong>
                <small>堂</small>
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
              <span>今日學生數</span>

              <div>
                <strong>{dashboard.studentCount}</strong>
                <small>位</small>
              </div>
            </div>

            <div className="coach-stat-decoration">
              👥
            </div>

          </div>

        </div>

        {/* 課表及學員 */}

        <div className="coach-content-grid">

          {/* 課表 */}

          <section className="coach-panel">

            <div className="coach-panel-title">
              <span>🗓️</span>
              <h3>今日課表</h3>
            </div>

            <div className="coach-schedule-list">

              {loading && (
                <div className="coach-empty">
                  載入中...
                </div>
              )}

              {!loading && schedules.length === 0 && (
                <div className="coach-empty">
                  這一天目前沒有已預約課程
                </div>
              )}

              {!loading && schedules.map(schedule => (

                <div
                  key={schedule.bookingid}
                  className="coach-schedule-card"
                >

                  <div className="schedule-time-column">

                    <strong>
                      {formatTime(schedule.starttime)}
                      {' - '}
                      {formatTime(schedule.endtime)}
                    </strong>

                    <span>已預約</span>

                  </div>

                  <div className="schedule-divider" />

                  <div className="schedule-info-column">

                    <h4>
                      {schedule.coursename ?? '—'}
                    </h4>

                    <p>
                      👤 學員：
                      {schedule.studentname ?? schedule.membername ?? '—'}
                    </p>

                  </div>

                  <div className="schedule-action-column">

                    <button
                      type="button"
                      className="schedule-detail-button"
                      onClick={() => openBookingModal(schedule)}
                    >
                      查看預約
                    </button>

                  </div>

                </div>

              ))}

            </div>

          </section>

          {/* 今日學員 */}

          <section className="coach-panel">

            <div className="coach-panel-title">
              <span>👥</span>
              <h3>今日學員</h3>
            </div>

            <div className="coach-student-table-wrapper">

              <table className="coach-student-table">

                <thead>
                  <tr>
                    <th>#</th>
                    <th>學員姓名</th>
                    <th>課程名稱</th>
                    <th>上課時段</th>
                  </tr>
                </thead>

                <tbody>

                  {studentRows.map((student, index) => (

                    <tr key={student.id}>

                      <td>{index + 1}</td>

                      <td>
                        <div className="student-name-cell">

                          <span className="student-avatar">
                            👤
                          </span>

                          <strong>
                            {student.membername}
                          </strong>

                        </div>
                      </td>

                      <td>{student.coursename}</td>
                      <td>{student.time}</td>

                    </tr>

                  ))}

                </tbody>

              </table>

            </div>

          </section>

        </div>

      </section>

      {/* =====================================================
          查看預約 Modal
      ===================================================== */}

      {showBookingModal && selectedBooking && (

        <div
          className="booking-detail-overlay"
          onMouseDown={event => {
            if (event.target === event.currentTarget) {
              closeBookingModal()
            }
          }}
        >

          <div className="booking-detail-modal">

            <div className="booking-detail-header">

              <div>
                <h3>預約資訊</h3>
                <p>
                  查看課程資訊，或協助學員修改／取消預約。
                </p>
              </div>

              <button
                type="button"
                className="booking-detail-close"
                disabled={isCancelling || loadingEditDates}
                onClick={closeBookingModal}
              >
                ×
              </button>

            </div>

            <div className="booking-detail-status">
              <span className="status-dot" />
              已預約
            </div>

            <div className="booking-detail-content">

              <div className="booking-detail-row">

                <div className="booking-detail-icon">
                  👤
                </div>

                <span>學員</span>

                <strong>
                  {selectedBooking.studentname ?? selectedBooking.membername ?? '—'}
                </strong>

              </div>

              <div className="booking-detail-row">

                <div className="booking-detail-icon">
                  🏋
                </div>

                <span>課程</span>

                <strong>
                  {selectedBooking.coursename ?? '—'}
                </strong>

              </div>

              <div className="booking-detail-row">

                <div className="booking-detail-icon">
                  📅
                </div>

                <span>日期</span>

                <strong>
                  {formatDate(selectedDate)}
                </strong>

              </div>

              <div className="booking-detail-row">

                <div className="booking-detail-icon">
                  ◷
                </div>

                <span>時段</span>

                <strong>
                  {formatTime(selectedBooking.starttime)}
                  {' - '}
                  {formatTime(selectedBooking.endtime)}
                </strong>

              </div>

            </div>

            <div
              className={
                canManageBooking(selectedBooking)
                  ? 'booking-detail-warning'
                  : 'booking-detail-warning disabled-warning'
              }
            >

              <span>!</span>

              <p>
                {canManageBooking(selectedBooking)
                  ? '課程開始前，教練可協助學員修改或取消預約。'
                  : '此課程已開始，無法再修改或取消預約。'}
              </p>

            </div>

            <div className="booking-detail-actions">

              <button
                type="button"
                className="booking-detail-back-btn"
                disabled={isCancelling || loadingEditDates}
                onClick={closeBookingModal}
              >
                關閉
              </button>

              <button
                type="button"
                className="booking-detail-edit-btn"
                disabled={
                  isCancelling ||
                  loadingEditDates ||
                  !canManageBooking(selectedBooking)
                }
                onClick={openEditBooking}
              >
                {loadingEditDates
                  ? '讀取中...'
                  : !canManageBooking(selectedBooking)
                    ? '已無法修改'
                    : '修改預約'}
              </button>

              <button
                type="button"
                className="booking-detail-cancel-btn"
                disabled={
                  isCancelling ||
                  loadingEditDates ||
                  !canManageBooking(selectedBooking)
                }
                onClick={handleCoachCancel}
              >
                {isCancelling
                  ? '取消中...'
                  : !canManageBooking(selectedBooking)
                    ? '已無法取消'
                    : '取消預約'}
              </button>

            </div>

          </div>

        </div>

      )}

      {/* =====================================================
          修改預約 Modal
      ===================================================== */}

      {showEditModal && selectedBooking && (

        <div className="booking-detail-overlay">

          <div className="coach-edit-modal">

            <div className="booking-detail-header">

              <div>
                <h3>修改預約</h3>
                <p>請重新選擇新的日期與時段。</p>
              </div>

              <button
                type="button"
                className="booking-detail-close"
                disabled={isRescheduling}
                onClick={closeEditModal}
              >
                ×
              </button>

            </div>

            {/* 原預約資訊 */}

            <div className="coach-edit-original">

              <div>
                <span>學員</span>
                <strong>
                  {selectedBooking.studentname ?? selectedBooking.membername ?? '—'}
                </strong>
              </div>

              <div>
                <span>課程</span>
                <strong>
                  {selectedBooking.coursename ?? '—'}
                </strong>
              </div>

              <div>
                <span>原日期</span>
                <strong>{formatDate(selectedDate)}</strong>
              </div>

              <div>
                <span>原時段</span>
                <strong>
                  {formatTime(selectedBooking.starttime)}
                  {' - '}
                  {formatTime(selectedBooking.endtime)}
                </strong>
              </div>

            </div>

            {/* 選擇新的日期 */}

            <div className="coach-edit-section">

              <h4>1. 選擇新的日期</h4>

              <div className="coach-edit-calendar">

                <Calendar
                  value={editSelectedDate}
                  minDate={getTodayStart()}
                  onChange={handleEditDateChange}
                  tileDisabled={({ date }) => {
                    const dateString = getLocalDateString(date)
                    return !availableDates.includes(dateString)
                  }}
                />

              </div>

            </div>

            {/* 選擇新的時段 */}

            {editSelectedDate && (

              <div className="coach-edit-section">

                <h4>2. 選擇新的時段</h4>

                {loadingEditSlots && (

                  <div className="coach-edit-empty">
                    時段載入中...
                  </div>

                )}

                {!loadingEditSlots && scheduleOptions.length === 0 && (

                  <div className="coach-edit-empty">
                    此日期目前沒有可用時段
                  </div>

                )}

                {!loadingEditSlots && scheduleOptions.length > 0 && (

                  <div className="coach-edit-time-list">

                    {scheduleOptions.map(slot => {

                      const available = slot.status === 'available'

                      return (

                        <button
                          key={slot.scheduleid}
                          type="button"
                          disabled={!available}
                          className={
                            selectedScheduleId === slot.scheduleid
                              ? 'coach-edit-time-btn selected'
                              : available
                                ? 'coach-edit-time-btn'
                                : 'coach-edit-time-btn disabled'
                          }
                          onClick={() => setSelectedScheduleId(slot.scheduleid)}
                        >

                          <strong>
                            {formatTime(slot.starttime)}
                            {' - '}
                            {formatTime(slot.endtime)}
                          </strong>

                          <span>
                            {slot.status === 'available'
                              ? '可預約'
                              : slot.status === 'booked'
                                ? '已預約'
                                : slot.status === 'closed'
                                  ? '已過時間'
                                  : slot.status}
                          </span>

                        </button>

                      )

                    })}

                  </div>

                )}

              </div>

            )}

            {/* 已選擇的新日期與時間 */}

            {editSelectedDate && selectedScheduleId !== null && (

              <div className="coach-edit-new-summary">

                <span>新預約：</span>

                <strong>

                  {formatDate(getLocalDateString(editSelectedDate))}

                  {'　'}

                  {formatTime(
                    scheduleOptions.find(
                      item => item.scheduleid === selectedScheduleId
                    )?.starttime
                  )}

                  {' - '}

                  {formatTime(
                    scheduleOptions.find(
                      item => item.scheduleid === selectedScheduleId
                    )?.endtime
                  )}

                </strong>

              </div>

            )}

            {/* 修改按鈕 */}

            <div className="coach-edit-actions">

              <button
                type="button"
                className="booking-detail-back-btn"
                disabled={isRescheduling}
                onClick={closeEditModal}
              >
                返回
              </button>

              <button
                type="button"
                className="coach-edit-confirm-btn"
                disabled={
                  selectedScheduleId === null ||
                  isRescheduling
                }
                onClick={confirmReschedule}
              >
                {isRescheduling ? '修改中...' : '確認修改'}
              </button>

            </div>

          </div>

        </div>

      )}

    </div>
  )
}

export default CoachDashboard
