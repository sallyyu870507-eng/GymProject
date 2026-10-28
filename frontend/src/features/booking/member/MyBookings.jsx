import { sessionFetch } from '../../../sessionFetch.js'
import { useEffect, useState } from 'react'
import Calendar from 'react-calendar'

import 'react-calendar/dist/Calendar.css'
import './MyBookings.css'


function MyBookings() {

  const [bookings, setBookings] =
    useState([])

  const [loading, setLoading] =
    useState(true)

  const [error, setError] =
    useState('')

  const [activeTab, setActiveTab] =
    useState('upcoming')

  const [cancelBookingData, setCancelBookingData] =
    useState(null)

  const [cancellingId, setCancellingId] =
    useState(null)

  const [editBookingData, setEditBookingData] =
    useState(null)

  const [availableDates, setAvailableDates] =
    useState([])

  const [scheduleOptions, setScheduleOptions] =
    useState([])

  const [selectedDate, setSelectedDate] =
    useState(null)

  const [selectedScheduleId, setSelectedScheduleId] =
    useState(null)

  const [isRescheduling, setIsRescheduling] =
    useState(false)

  const [successMessage, setSuccessMessage] =
    useState('')


  const loadBookings = async () => {

    const response =
      await sessionFetch(
        '/booking/my',
        {
          method: 'GET',
          credentials: 'include'
        }
      )

    if (!response.ok) {
      throw new Error(
        '取得預約紀錄失敗'
      )
    }

    const data =
      await response.json()

    setBookings(data)
  }


  useEffect(() => {

    loadBookings()
      .catch(() => {
        setError(
          '無法取得預約紀錄'
        )
      })
      .finally(() => {
        setLoading(false)
      })

  }, [])


  const isPastBooking = booking => {

    if (
      !booking.classdate ||
      !booking.endtime
    ) {
      return false
    }

    return new Date(
      `${booking.classdate}T${booking.endtime}`
    ) < new Date()
  }


  const canEditBooking = booking => {

    if (
      booking.bookingstatus !==
      'booked'
    ) {
      return false
    }

    const today =
      new Date()

    today.setHours(
      0, 0, 0, 0
    )

    const bookingDate =
      new Date(
        `${booking.classdate}T00:00:00`
      )

    return bookingDate > today
  }


  const canCancelBooking =
    booking => {

      return (
        booking.bookingstatus ===
        'booked'
        &&
        !isPastBooking(booking)
      )
    }


  const upcomingBookings =
    bookings
      .filter(
        booking =>
          !isPastBooking(booking)
      )
      .sort(
        (a, b) =>
          new Date(
            `${a.classdate}T${a.starttime}`
          )
          -
          new Date(
            `${b.classdate}T${b.starttime}`
          )
      )


  const historyBookings =
    bookings
      .filter(
        booking =>
          isPastBooking(booking)
      )
      .sort(
        (a, b) =>
          new Date(
            `${b.classdate}T${b.starttime}`
          )
          -
          new Date(
            `${a.classdate}T${a.starttime}`
          )
      )


  const displayedBookings =
    activeTab === 'upcoming'
      ? upcomingBookings
      : historyBookings


  const getStatusText =
    status => {

      if (status === 'booked') {
        return '已預約'
      }

      if (status === 'cancelled') {
        return '已取消'
      }

      if (status === 'completed') {
        return '已完成'
      }

      return status
    }


  const confirmCancelBooking =
    async () => {

      if (!cancelBookingData) {
        return
      }

      try {

        setCancellingId(
          cancelBookingData.bookingid
        )

        const response =
          await sessionFetch(
            `/booking/${cancelBookingData.bookingid}/cancel`,
            {
              method: 'PUT',
              credentials: 'include'
            }
          )

        const message =
          await response.text()

        if (!response.ok) {
          throw new Error(message)
        }

        await loadBookings()

        setCancelBookingData(null)

        setSuccessMessage(
          '預約已成功取消'
        )

      } catch (error) {

        alert(
          error.message ||
          '取消預約失敗'
        )

      } finally {

        setCancellingId(null)

      }
    }


  const openEditBooking =
    async booking => {

      setEditBookingData(booking)

      setSelectedScheduleId(null)

      setScheduleOptions([])

      setSelectedDate(
        new Date(
          `${booking.classdate}T00:00:00`
        )
      )

      try {

        const response =
          await sessionFetch(
            `/members/courses/${booking.membercourseid}/available-dates`,
            {
              method: 'GET',
              credentials: 'include'
            }
          )

        const data =
          await response.json()

        setAvailableDates(data)

      } catch {

        alert(
          '取得可修改日期失敗'
        )
      }
    }


  const loadScheduleOptions =
    async date => {

      if (!editBookingData) {
        return
      }

      const dateString =
        date.toLocaleDateString(
          'en-CA'
        )

      const response =
        await sessionFetch(
          `/members/courses/${editBookingData.membercourseid}/schedules?date=${dateString}`,
          {
            credentials: 'include'
          }
        )

      if (!response.ok) {
        throw new Error(
          '取得可預約時段失敗'
        )
      }

      const data =
        await response.json()

      setScheduleOptions(data)
    }


  const confirmReschedule =
    async () => {

      if (
        !editBookingData ||
        selectedScheduleId === null
      ) {
        return
      }

      try {

        setIsRescheduling(true)

        const response =
          await sessionFetch(
            `/booking/${editBookingData.bookingid}/reschedule`,
            {
              method: 'PUT',

              credentials: 'include',

              headers: {
                'Content-Type':
                  'application/json'
              },

              body:
                JSON.stringify({
                  newScheduleid:
                    selectedScheduleId
                })
            }
          )

        const message =
          await response.text()

        if (!response.ok) {
          throw new Error(message)
        }

        await loadBookings()

        setEditBookingData(null)

        setSuccessMessage(
          '預約修改成功'
        )

      } catch (error) {

        alert(
          error.message ||
          '修改預約失敗'
        )

      } finally {

        setIsRescheduling(false)

      }
    }


  if (editBookingData) {

    return (

      <div className="edit-booking-page">

        <h2 className="my-bookings-title">
          修改預約
        </h2>


        <div className="edit-booking-card">

          <div className="original-booking-card">

            <h3>
              原預約資訊
            </h3>

            <p>
              課程：
              {
                editBookingData.coursename
              }
            </p>

            <p>
              教練：
              {
                editBookingData.coachname
              }
            </p>

            <p>
              日期：
              {
                editBookingData.classdate
              }
            </p>

            <p>

              時段：

              {
                editBookingData
                  .starttime
                  ?.slice(0, 5)
              }

              {' - '}

              {
                editBookingData
                  .endtime
                  ?.slice(0, 5)
              }

            </p>

          </div>


          <div className="edit-booking-grid">

            <div className="edit-calendar-box">

              <Calendar

                value={selectedDate}

                minDate={
                  new Date()
                }

                tileDisabled={({ date }) => {

                  const value =
                    date.toLocaleDateString(
                      'en-CA'
                    )

                  return !availableDates
                    .includes(value)
                }}

                onChange={date => {

                  setSelectedDate(date)

                  setSelectedScheduleId(
                    null
                  )

                  loadScheduleOptions(
                    date
                  )
                }}
              />

            </div>


            <div className="edit-time-list">

              {scheduleOptions.map(
                schedule => (

                  <button
                    key={
                      schedule.scheduleid
                    }

                    disabled={
                      schedule.status ===
                      'booked'
                    }

                    className={
                      selectedScheduleId ===
                      schedule.scheduleid
                        ? 'edit-time-btn selected'
                        : 'edit-time-btn'
                    }

                    onClick={() =>
                      setSelectedScheduleId(
                        schedule.scheduleid
                      )
                    }
                  >

                    {
                      schedule.starttime
                        .slice(0, 5)
                    }

                    {' - '}

                    {
                      schedule.endtime
                        .slice(0, 5)
                    }

                  </button>

                )
              )}

            </div>

          </div>


          <div className="edit-actions">

            <button
              className="edit-back-button"

              onClick={() =>
                setEditBookingData(null)
              }
            >
              返回
            </button>

            <button
              className="edit-confirm-button"

              disabled={
                selectedScheduleId === null ||
                isRescheduling
              }

              onClick={
                confirmReschedule
              }
            >

              {
                isRescheduling
                  ? '修改中...'
                  : '確認修改'
              }

            </button>

          </div>

        </div>

      </div>
    )
  }


  if (loading) {
    return <div>載入中...</div>
  }


  if (error) {
    return <div>{error}</div>
  }


  return (

    <div className="my-bookings-page">


      <h2 className="my-bookings-title">

        我的預約

      </h2>


      {successMessage && (

        <div className="success-toast">

          ✓ {successMessage}

          <button
            onClick={() =>
              setSuccessMessage('')
            }
          >
            ×
          </button>

        </div>

      )}


      <div className="booking-main-card">


        <div className="booking-tabs">

          <button
            className={
              activeTab === 'upcoming'
                ? 'booking-tab active'
                : 'booking-tab'
            }

            onClick={() =>
              setActiveTab('upcoming')
            }
          >

            即將到來（{upcomingBookings.length}）

          </button>


          <button
            className={
              activeTab === 'history'
                ? 'booking-tab active'
                : 'booking-tab'
            }

            onClick={() =>
              setActiveTab('history')
            }
          >

            歷史紀錄（{historyBookings.length}）

          </button>

        </div>


        <div className="booking-table">


          <div
            className={
              activeTab === 'history'
                ? 'booking-table-header history'
                : 'booking-table-header'
            }
          >

            <div>課程</div>
            <div>教練</div>
            <div>日期</div>
            <div>時段</div>
            <div>地點</div>
            <div>狀態</div>

            {
              activeTab ===
              'upcoming'
              &&
              <div>操作</div>
            }

          </div>


          {displayedBookings.map(
            booking => (

              <div
                key={
                  booking.bookingid
                }

                className={
                  activeTab ===
                  'history'
                    ? 'booking-row history'
                    : 'booking-row'
                }
              >

                <div className="booking-course">

                  <strong>
                    {
                      booking.coursename
                    }
                  </strong>

                  <span>
                    私人教練課
                  </span>

                </div>


                <div>
                  {booking.coachname}
                </div>

                <div>
                  {booking.classdate}
                </div>

                <div>

                  {
                    booking.starttime
                      ?.slice(0, 5)
                  }

                  {' - '}

                  {
                    booking.endtime
                      ?.slice(0, 5)
                  }

                </div>

                <div>
                  {
                    booking.classroom
                    || '未安排'
                  }
                </div>


                <div>

                  <span
                    className={
                      `booking-status ${booking.bookingstatus}`
                    }
                  >
                    {
                      getStatusText(
                        booking.bookingstatus
                      )
                    }
                  </span>

                </div>


                {
                  activeTab ===
                  'upcoming'
                  &&

                  <div className="booking-actions">

                    {
                      canEditBooking(
                        booking
                      )
                      &&

                      <button
                        className="edit-booking-btn"

                        onClick={() =>
                          openEditBooking(
                            booking
                          )
                        }
                      >
                        修改預約
                      </button>
                    }


                    {
                      canCancelBooking(
                        booking
                      )
                      &&

                      <button
                        className="cancel-booking-btn"

                        onClick={() =>
                          setCancelBookingData(
                            booking
                          )
                        }
                      >
                        取消預約
                      </button>
                    }

                  </div>
                }

              </div>

            )
          )}

        </div>

      </div>


      {cancelBookingData && (

        <div className="modal-overlay">

          <div className="cancel-modal">

            <h3>
              取消預約確認
            </h3>

            <p>
              確定要取消
              「
              {
                cancelBookingData
                  .coursename
              }
              」嗎？
            </p>


            <div className="cancel-modal-actions">

              <button
                className="modal-back-btn"

                onClick={() =>
                  setCancelBookingData(
                    null
                  )
                }
              >
                返回
              </button>

              <button
                className="modal-confirm-cancel-btn"

                disabled={
                  cancellingId !== null
                }

                onClick={
                  confirmCancelBooking
                }
              >
                確認取消
              </button>

            </div>

          </div>

        </div>

      )}

    </div>
  )
}


export default MyBookings