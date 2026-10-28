import { sessionFetch } from '../../../sessionFetch.js'
import { useEffect, useState } from 'react'
import Calendar from 'react-calendar'

import 'react-calendar/dist/Calendar.css'
import './BookingCourse.css'


function BookingCourse() {

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

  const loadCourses = () => {

    return sessionFetch(
      '/members/courses',
      {
        method: 'GET',
        credentials: 'include'
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

        console.log(
          '會員課程：',
          data
        )

        setCourses(data)

      })

  }


  // =====================================================
  // 初次載入課程
  // =====================================================

  useEffect(() => {

    loadCourses()
      .catch(error => {

        console.error(
          '取得課程失敗：',
          error
        )

      })

  }, [])


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


    sessionFetch(
      `/members/courses/${selectedCourse}/available-dates`,
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


    sessionFetch(
      `/members/courses/${selectedCourse}/schedules?date=${dateString}`,
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


    sessionFetch(
      '/booking',
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
         * 注意：
         * 這裡不能 setScheduleOptions([])
         *
         * 因為 Step 4 還需要
         * selectedScheduleData
         * 顯示最後預約的時段。
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

        alert(
          '預約失敗：' +
          error.message
        )

      })

  }


  return (

    <div className="booking-course-page">


      {/* =================================================
          卡片外頁面標題
      ================================================= */}

      <h2 className="booking-course-title">

        預約課程

      </h2>


      {/* =================================================
          白色大卡片
      ================================================= */}

      <section className="booking-page">


        {/* =================================================
            上方說明
        ================================================= */}

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


          {/* Step 1 */}

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


          {/* Step 2 */}

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


          {/* Step 3 */}

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


          {/* Step 4 */}

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
            選擇課程
        ================================================= */}

        {currentStep === 1 && (

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


              {courses.map(course => {

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


                    {/* 課程圖示 */}

                    <div className="course-card-icon">

                      {
                        course.coursename
                          ?.includes('拳')
                          ? '🥊'
                          : '🏋'
                      }

                    </div>


                    {/* 課程資訊 */}

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


                    {/* 剩餘堂數 */}

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

              })}

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

        )}


        {/* =================================================
            STEP 2
            選擇日期
        ================================================= */}

        {currentStep === 2 && (

          <div className="course-section">


            <div className="section-title">

              <h3>

                選擇日期

              </h3>

              <p>

                請選擇您想預約上課的日期。

              </p>

            </div>


            {/* 已選內容 */}

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


            {/* 月曆 */}

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

        )}


        {/* =================================================
            STEP 3
            選擇時段
        ================================================= */}

        {currentStep === 3 && (

          <div className="course-section">


            <div className="section-title">

              <h3>

                選擇時段

              </h3>

              <p>

                請選擇您想預約的上課時段。

              </p>

            </div>


            {/* 已選內容 */}

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


            {/* 時段選項 */}

            <div className="time-list">


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
              )}

            </div>


            {/* 目前選擇時段 */}

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

        )}


        {/* =================================================
            STEP 4
            預約完成
        ================================================= */}

        {currentStep === 4 && (

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


            {/* 最終摘要 */}

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

          </div>

        )}

      </section>

    </div>

  )

}


export default BookingCourse