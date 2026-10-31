import { showToast } from '../../../notifications.js'
const showErrorToast = message => showToast(message, { type: 'error' })
import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router'
import Calendar from 'react-calendar'

import 'react-calendar/dist/Calendar.css'
import './BookingCourse.css'


function BookingCourse() {
  const [searchParams] = useSearchParams()
  const requestedPlan = searchParams.get('membercourseid')

  const [currentStep, setCurrentStep] =
    useState(1)

  const [courses, setCourses] =
    useState([])

  const [selectedCourse, setSelectedCourse] =
    useState(null)

  const [availableDates, setAvailableDates] =
    useState([])

  const [scheduleOptions, setScheduleOptions] =
    useState([])

  const [selectedDate, setSelectedDate] =
    useState(null)

  const [selectedTime, setSelectedTime] =
    useState(null)

  const [isBooking, setIsBooking] =
    useState(false)


  // =====================================================
  // 小圖示
  // =====================================================

  const CourseIcon = () => (
    <span className="booking-mini-icon orange">
      🏋
    </span>
  )


  const CoachIcon = () => (
    <span className="booking-mini-icon">
      👤
    </span>
  )


  const DateIcon = () => (
    <span className="booking-mini-icon">
      📅
    </span>
  )


  const TimeIcon = () => (
    <span className="booking-mini-icon">
      ◷
    </span>
  )


  // =====================================================
  // 取得會員已購買課程
  // =====================================================

  const loadCourses = (signal) => {

    return fetch(
      '/api/member/courses',
      {
        method: 'GET',
        credentials: 'include',
        signal
      }
    )
      .then(response => {

        if (!response.ok) {

          throw new Error(
            '取得課程失敗'
          )
        }

        return response.json()

      })
      .then(data => {
        if (!Array.isArray(data)) throw new Error('已購課程回傳格式不正確')
        if (signal?.aborted) return data

        console.log(
          '會員課程：',
          data
        )

        setCourses(data)
        return data

      })
  }


  // =====================================================
  // 初次載入課程
  // =====================================================

  useEffect(() => {
    const controller = new AbortController()
    setCurrentStep(1)
    setSelectedCourse(null)
    setSelectedDate(null)
    setSelectedTime(null)
    setAvailableDates([])
    setScheduleOptions([])

    loadCourses(controller.signal)
      .then(data => {
        if (controller.signal.aborted || requestedPlan === null) return
        const id = /^[1-9]\d*$/.test(requestedPlan) ? Number(requestedPlan) : NaN
        const course = Number.isSafeInteger(id)
          ? data.find(item => item.membercourseid === id && item.remainingsessions > 0)
          : null
        if (course) setSelectedCourse(course.membercourseid)
        else showToast('此購課方案無法預選，可能已失效或沒有剩餘堂數，請重新選擇課程。', { type: 'info' })
      })
      .catch(error => {
        if (controller.signal.aborted) return

        console.error(
          '取得課程失敗：',
          error
        )
        showErrorToast(error.message || '取得課程失敗')

      })

    return () => controller.abort()
  }, [requestedPlan])


  // =====================================================
  // Step 2
  // 取得可預約日期
  // =====================================================

  useEffect(() => {

    if (
      currentStep !== 2 ||
      selectedCourse === null
    ) {

      return
    }


    fetch(
      `/api/member/courses/${selectedCourse}/available-dates`,
      {
        method: 'GET',
        credentials: 'include'
      }
    )
      .then(response => {

        if (!response.ok) {

          throw new Error(
            '取得可預約日期失敗'
          )
        }

        return response.json()

      })
      .then(data => {

        console.log(
          '可預約日期：',
          data
        )

        setAvailableDates(data)

      })
      .catch(error => {

        console.error(
          '取得可預約日期失敗：',
          error
        )

      })

  }, [
    currentStep,
    selectedCourse
  ])


  // =====================================================
  // Step 3
  // 取得指定日期時段
  // =====================================================

  useEffect(() => {

    if (
      currentStep !== 3 ||
      selectedCourse === null ||
      selectedDate === null
    ) {

      return
    }


    const dateString =
      selectedDate.toLocaleDateString(
        'en-CA'
      )


    fetch(
      `/api/member/courses/${selectedCourse}/schedules?date=${dateString}`,
      {
        method: 'GET',
        credentials: 'include'
      }
    )
      .then(response => {

        if (!response.ok) {

          throw new Error(
            '取得時段失敗'
          )
        }

        return response.json()

      })
      .then(data => {

        console.log(
          '可預約時段：',
          data
        )

        setScheduleOptions(data)

      })
      .catch(error => {

        console.error(
          '取得時段失敗：',
          error
        )

      })

  }, [
    currentStep,
    selectedCourse,
    selectedDate
  ])


  // =====================================================
  // 選中的課程
  // =====================================================

  const selectedCourseData =
    courses.find(
      course =>
        course.membercourseid ===
        selectedCourse
    )


  // =====================================================
  // 選中的時段
  // =====================================================

  const selectedScheduleData =
    scheduleOptions.find(
      schedule =>
        schedule.scheduleid ===
        selectedTime
    )


  // =====================================================
  // 建立預約
  // =====================================================

  const handleBooking = () => {

    if (
      isBooking ||
      selectedCourse === null ||
      selectedTime === null
    ) {

      return
    }


    setIsBooking(true)


    const bookingData = {

      membercourseid:
        selectedCourse,

      scheduleid:
        selectedTime,

      bookingstatus:
        'booked',

      note:
        ''
    }


    fetch(
      '/api/member/bookings',
      {
        method: 'POST',

        credentials: 'include',

        headers: {
          'Content-Type':
            'application/json'
        },

        body:
          JSON.stringify(
            bookingData
          )
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
      .then(() => {

        return loadCourses()

      })
      .then(() => {

        /*
         * 這裡不能清空 scheduleOptions
         * 因為 Step 4 還需要 selectedScheduleData
         * 顯示最後預約成功的時段
         */

        setIsBooking(false)

        setCurrentStep(4)

      })
      .catch(error => {

        console.error(
          '預約失敗：',
          error
        )

        setIsBooking(false)

        showErrorToast(
          '預約失敗：' +
          error.message
        )

      })
  }


  // =====================================================
  // 預約完成後重新預約
  // =====================================================

  const handleBookingAgain = () => {

    setCurrentStep(1)

    setSelectedCourse(null)
    setSelectedDate(null)
    setSelectedTime(null)

    setAvailableDates([])
    setScheduleOptions([])

    setIsBooking(false)
  }


  return (

    <div className="booking-course-page">


      <h2 className="booking-course-title">
        預約課程
      </h2>


      <section className="booking-page">


        <div className="booking-header">

          <p>
            請依序完成以下步驟，
            選擇您已購買的課程後，
            再選擇日期與時段。
          </p>

        </div>


        {/* =================================================
            步驟列
        ================================================= */}

        <div className="booking-steps">


          <div className="step-group">

            <div
              className={
                currentStep >= 1
                  ? 'step active'
                  : 'step'
              }
            >

              <div className="step-number">
                1
              </div>

              <span>
                選擇課程
              </span>

            </div>


            <div
              className={
                currentStep >= 2
                  ? 'step-line active-line'
                  : 'step-line'
              }
            />

          </div>


          <div className="step-group">

            <div
              className={
                currentStep >= 2
                  ? 'step active'
                  : 'step'
              }
            >

              <div className="step-number">
                2
              </div>

              <span>
                選擇日期
              </span>

            </div>


            <div
              className={
                currentStep >= 3
                  ? 'step-line active-line'
                  : 'step-line'
              }
            />

          </div>


          <div className="step-group">

            <div
              className={
                currentStep >= 3
                  ? 'step active'
                  : 'step'
              }
            >

              <div className="step-number">
                3
              </div>

              <span>
                選擇時段
              </span>

            </div>


            <div
              className={
                currentStep >= 4
                  ? 'step-line active-line'
                  : 'step-line'
              }
            />

          </div>


          <div className="step-group">

            <div
              className={
                currentStep >= 4
                  ? 'step active'
                  : 'step'
              }
            >

              <div className="step-number">
                4
              </div>

              <span>
                預約完成
              </span>

            </div>

          </div>

        </div>


        {/* =================================================
            STEP 1
        ================================================= */}

        {
          currentStep === 1 && (

            <div className="course-section">

              <div className="section-title">

                <h3>
                  選擇您已購買的課程
                </h3>

                <p>
                  請選擇本次想要預約的課程。
                </p>

              </div>


              <div className="course-list">

                {
                  courses.map(course => {

                    const isSelected =
                      selectedCourse ===
                      course.membercourseid


                    return (

                      <div
                        key={
                          course.membercourseid
                        }

                        className={
                          isSelected
                            ? 'course-card selected'
                            : 'course-card'
                        }

                        onClick={() => {

                          setSelectedCourse(
                            course.membercourseid
                          )

                          setSelectedDate(null)

                          setSelectedTime(null)

                          setAvailableDates([])

                          setScheduleOptions([])

                        }}
                      >


                        <div className="course-card-icon">

                          {
                            course.coursename
                              ?.includes('拳')
                              ? '🥊'
                              : '🏋'
                          }

                        </div>


                        <div className="course-info">

                          <h4>
                            {course.coursename}
                          </h4>


                          <p>

                            <CoachIcon />

                            教練：

                            {
                              course.coachname
                            }

                          </p>

                        </div>


                        <div className="course-count">

                          <span>
                            剩餘堂數
                          </span>

                          <strong>
                            {
                              course.remainingsessions
                            }
                          </strong>

                          <span>
                            堂
                          </span>

                        </div>

                      </div>

                    )

                  })
                }

              </div>


              <div className="booking-actions step-one-actions">

                <button
                  className="next-button"

                  disabled={
                    selectedCourse === null
                  }

                  onClick={() =>
                    setCurrentStep(2)
                  }
                >
                  下一步
                </button>

              </div>

            </div>

          )
        }


        {/* =================================================
            STEP 2
        ================================================= */}

        {
          currentStep === 2 && (

            <div className="course-section">

              <div className="section-title">

                <h3>
                  選擇日期
                </h3>

                <p>
                  請選擇您想預約上課的日期。
                </p>

              </div>


              <div className="booking-summary">

                <div className="summary-row">

                  <CourseIcon />

                  <span>
                    課程：
                  </span>

                  <strong>
                    {
                      selectedCourseData
                        ?.coursename
                    }
                  </strong>

                </div>


                <div className="summary-row">

                  <CoachIcon />

                  <span>
                    教練：
                  </span>

                  <strong>
                    {
                      selectedCourseData
                        ?.coachname
                    }
                  </strong>

                </div>

              </div>


              <div className="calendar-container">

                <Calendar

                  value={
                    selectedDate
                  }

                  minDate={
                    new Date()
                  }

                  onChange={date => {

                    setSelectedDate(date)

                    setSelectedTime(null)

                    setScheduleOptions([])

                  }}

                  tileDisabled={({ date }) => {

                    const dateString =
                      date.toLocaleDateString(
                        'en-CA'
                      )

                    return !availableDates.includes(
                      dateString
                    )

                  }}
                />

              </div>


              <div className="selected-date-summary">

                <DateIcon />

                <span>
                  目前選擇日期：
                </span>

                <strong>

                  {
                    selectedDate

                      ? selectedDate
                          .toLocaleDateString(
                            'zh-TW'
                          )

                      : '尚未選擇'
                  }

                </strong>

              </div>


              <div className="booking-actions">

                <button
                  className="back-button"

                  onClick={() =>
                    setCurrentStep(1)
                  }
                >
                  上一步
                </button>


                <button
                  className="next-button"

                  disabled={
                    selectedDate === null
                  }

                  onClick={() =>
                    setCurrentStep(3)
                  }
                >
                  下一步
                </button>

              </div>

            </div>

          )
        }


        {/* =================================================
            STEP 3
        ================================================= */}

        {
          currentStep === 3 && (

            <div className="course-section">

              <div className="section-title">

                <h3>
                  選擇時段
                </h3>

                <p>
                  請選擇您想預約的上課時段。
                </p>

              </div>


              <div className="booking-summary">

                <div className="summary-row">

                  <CourseIcon />

                  <span>
                    課程：
                  </span>

                  <strong>
                    {
                      selectedCourseData
                        ?.coursename
                    }
                  </strong>

                </div>


                <div className="summary-row">

                  <CoachIcon />

                  <span>
                    教練：
                  </span>

                  <strong>
                    {
                      selectedCourseData
                        ?.coachname
                    }
                  </strong>

                </div>


                <div className="summary-row">

                  <DateIcon />

                  <span>
                    日期：
                  </span>

                  <strong>
                    {
                      selectedDate
                        ?.toLocaleDateString(
                          'zh-TW'
                        )
                    }
                  </strong>

                </div>

              </div>


              <div className="time-list">

                {
                  scheduleOptions.map(
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
                          schedule.status ===
                          'booked'

                            ? 'time-card disabled-time'

                            : selectedTime ===
                              schedule.scheduleid

                              ? 'time-card selected-time'

                              : 'time-card available-time'
                        }

                        onClick={() => {

                          if (
                            schedule.status ===
                            'available'
                          ) {

                            setSelectedTime(
                              schedule.scheduleid
                            )

                          }

                        }}
                      >


                        <div className="time-card-main">

                          <TimeIcon />

                          <strong>

                            {
                              schedule.starttime
                                ?.substring(0, 5)
                            }

                            {' - '}

                            {
                              schedule.endtime
                                ?.substring(0, 5)
                            }

                          </strong>

                        </div>


                        <span>

                          {
                            schedule.status ===
                            'booked'

                              ? '已被預約'

                              : '可預約'
                          }

                        </span>

                      </button>

                    )
                  )
                }

              </div>


              <div className="selected-time-summary">

                <TimeIcon />

                <span>
                  目前選擇時段：
                </span>

                <strong>

                  {
                    selectedScheduleData

                      ? `${selectedScheduleData.starttime.substring(0, 5)} - ${selectedScheduleData.endtime.substring(0, 5)}`

                      : '尚未選擇'
                  }

                </strong>

              </div>


              <div className="booking-actions">

                <button
                  className="back-button"

                  disabled={
                    isBooking
                  }

                  onClick={() =>
                    setCurrentStep(2)
                  }
                >
                  上一步
                </button>


                <button
                  className="next-button"

                  disabled={
                    selectedTime === null ||
                    isBooking
                  }

                  onClick={
                    handleBooking
                  }
                >

                  {
                    isBooking
                      ? '預約中...'
                      : '確認預約'
                  }

                </button>

              </div>

            </div>

          )
        }


        {/* =================================================
            STEP 4
        ================================================= */}

        {
          currentStep === 4 && (

            <div className="course-section">


              <div className="success-box">

                <div className="success-icon">
                  ✓
                </div>

                <h3>
                  預約完成
                </h3>

                <p>
                  您的私人教練課程已完成預約。
                </p>

              </div>


              <div className="booking-summary final-summary">


                <div className="summary-row">

                  <CourseIcon />

                  <span>
                    課程：
                  </span>

                  <strong>
                    {
                      selectedCourseData
                        ?.coursename
                    }
                  </strong>

                </div>


                <div className="summary-row">

                  <CoachIcon />

                  <span>
                    教練：
                  </span>

                  <strong>
                    {
                      selectedCourseData
                        ?.coachname
                    }
                  </strong>

                </div>


                <div className="summary-row">

                  <DateIcon />

                  <span>
                    日期：
                  </span>

                  <strong>
                    {
                      selectedDate
                        ?.toLocaleDateString(
                          'zh-TW'
                        )
                    }
                  </strong>

                </div>


                <div className="summary-row">

                  <TimeIcon />

                  <span>
                    時段：
                  </span>

                  <strong>

                    {
                      selectedScheduleData

                        ? `${selectedScheduleData.starttime.substring(0, 5)} - ${selectedScheduleData.endtime.substring(0, 5)}`

                        : ''
                    }

                  </strong>

                </div>

              </div>


              <div className="booking-actions success-actions">

                <button
                  className="next-button"

                  onClick={
                    handleBookingAgain
                  }
                >
                  返回重新預約
                </button>

              </div>

            </div>

          )
        }

      </section>

    </div>
  )
}


export default BookingCourse
