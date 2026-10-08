import { useEffect, useState } from 'react'

import Calendar from 'react-calendar'

import 'react-calendar/dist/Calendar.css'


function BookingCourse() {

  const [currentStep, setCurrentStep] = useState(1)

  const [courses, setCourses] = useState([])

  const [selectedCourse, setSelectedCourse] = useState(null)

  const [selectedCoach, setSelectedCoach] = useState(null)

  const [availableDates, setAvailableDates] = useState([])

  const [scheduleOptions, setScheduleOptions] = useState([])

  const [selectedDate, setSelectedDate] = useState(new Date())

  const [selectedTime, setSelectedTime] = useState(null)

  const [isBooking, setIsBooking] = useState(false)



  // =========================
  // 抓會員已購買課程
  // =========================

  const loadCourses = () => {

    return fetch('http://localhost:8080/members/courses', {
      method: 'GET',
      credentials: 'include'
    })

      .then(response => {

        if (!response.ok) {
          throw new Error('取得課程失敗')
        }

        return response.json()
      })

      .then(data => {

        console.log('後端傳回的課程:', data)

        setCourses(data)

      })

      .catch(error => {

        console.error('取得課程失敗:', error)

        throw error

      })

  }



  // 頁面第一次載入時抓課程
  useEffect(() => {

    loadCourses()

  }, [])



  // =========================
  // STEP 3
  // 抓可預約日期
  // =========================

  useEffect(() => {

    if (
      currentStep !== 3 ||
      selectedCourse === null
    ) {
      return
    }

    fetch(
      `http://localhost:8080/members/courses/${selectedCourse}/available-dates`,
      {
        method: 'GET',
        credentials: 'include'
      }
    )

      .then(response => {

        if (!response.ok) {
          throw new Error('取得可預約日期失敗')
        }

        return response.json()
      })

      .then(data => {

        console.log('後端傳回的可預約日期:', data)

        setAvailableDates(data)

      })

      .catch(error => {

        console.error('取得可預約日期失敗:', error)

      })

  }, [currentStep, selectedCourse])



  // =========================
  // STEP 4
  // 抓指定日期的時段
  // =========================

  useEffect(() => {

    if (
      currentStep !== 4 ||
      selectedCourse === null ||
      selectedDate === null
    ) {
      return
    }

    const dateString =
      selectedDate.toLocaleDateString('en-CA')

    fetch(
      `http://localhost:8080/members/courses/${selectedCourse}/schedules?date=${dateString}`,
      {
        method: 'GET',
        credentials: 'include'
      }
    )

      .then(response => {

        if (!response.ok) {
          throw new Error('取得時段失敗')
        }

        return response.json()
      })

      .then(data => {

        console.log('後端傳回的時段:', data)

        setScheduleOptions(data)

      })

      .catch(error => {

        console.error('取得時段失敗:', error)

      })

  }, [currentStep, selectedCourse, selectedDate])



  // =========================
  // 找目前選到的完整課程資料
  // =========================

  const selectedCourseData = courses.find(
    course =>
      course.membercourseid === selectedCourse
  )



  // =========================
  // 找目前選到的完整時段資料
  // =========================

  const selectedScheduleData =
    scheduleOptions.find(
      schedule =>
        schedule.scheduleid === selectedTime
    )



  // =========================
  // 建立預約
  // =========================

  const handleBooking = () => {

    // 避免連點
    if (isBooking) {
      return
    }

    // 基本防呆
    if (
      selectedCourse === null ||
      selectedTime === null
    ) {
      return
    }


    setIsBooking(true)


    const bookingData = {

      membercourseid: selectedCourse,

      scheduleid: selectedTime,

      bookingstatus: 'booked',

      note: ''

    }


    fetch(
      'http://localhost:8080/booking',
      {

        method: 'POST',

        credentials: 'include',

        headers: {
          'Content-Type': 'application/json'
        },

        body: JSON.stringify(bookingData)

      }
    )

      .then(async response => {

        if (!response.ok) {

          const errorMessage =
            await response.text()

          throw new Error(errorMessage)

        }

        return response.json()

      })

      .then(data => {

        console.log('預約成功:', data)

        // 預約成功後重新抓會員課程
        return loadCourses()

      })

      .then(() => {

        // 清掉舊的可預約資料
        setAvailableDates([])

        setIsBooking(false)

        // 成功後才進 STEP 5
        setCurrentStep(5)

      })

      .catch(error => {

        console.error('預約失敗:', error)

        setIsBooking(false)

        alert(
          '預約失敗：' + error.message
        )

      })

  }



  return (

    <section className="booking-page">



      {/* =========================
          標題
      ========================= */}

      <div className="booking-header">

        <h2>
          預約私人教練課
        </h2>

        <p>
          請依序完成以下步驟，選擇您已購買的課程後，
          再選擇教練、日期與時段。
        </p>

      </div>



      {/* =========================
          上方步驟列
      ========================= */}

      <div className="booking-steps">


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
        >
        </div>



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
            選擇教練
          </span>

        </div>



        <div
          className={
            currentStep >= 3
              ? 'step-line active-line'
              : 'step-line'
          }
        >
        </div>



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
            選擇日期
          </span>

        </div>



        <div
          className={
            currentStep >= 4
              ? 'step-line active-line'
              : 'step-line'
          }
        >
        </div>



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
            選擇時段
          </span>

        </div>



        <div
          className={
            currentStep >= 5
              ? 'step-line active-line'
              : 'step-line'
          }
        >
        </div>



        <div
          className={
            currentStep >= 5
              ? 'step active'
              : 'step'
          }
        >

          <div className="step-number">
            5
          </div>

          <span>
            預約完成
          </span>

        </div>


      </div>



      {/* =========================
          STEP 1 選擇課程
      ========================= */}

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


            {courses.map(course => (

              <div

                key={
                  course.membercourseid
                }

                className={
                  selectedCourse ===
                  course.membercourseid
                    ? 'course-card selected'
                    : 'course-card'
                }

                onClick={() => {

                  setSelectedCourse(
                    course.membercourseid
                  )

                  // 換課程時清掉後面的選擇
                  setSelectedCoach(null)

                  setSelectedTime(null)

                  setAvailableDates([])

                  setScheduleOptions([])

                }}

              >


                <div className="course-info">

                  <h4>
                    {course.coursename}
                  </h4>

                  <p>
                    教練：
                    {course.coachname}
                  </p>

                </div>



                <div className="course-count">

                  <span>
                    剩餘堂數
                  </span>

                  <strong>
                    {course.remainingsessions}
                  </strong>

                  <span>
                    堂
                  </span>

                </div>


              </div>

            ))}


          </div>



          <div className="booking-actions">

            <button

              className="next-button"

              onClick={() =>
                setCurrentStep(2)
              }

              disabled={
                selectedCourse === null
              }

            >

              下一步

            </button>

          </div>


        </div>

      )}



      {/* =========================
          STEP 2 選擇教練
      ========================= */}

      {currentStep === 2 && (

        <div className="course-section">


          <div className="section-title">

            <h3>
              選擇教練
            </h3>

            <p>
              請選擇您想預約的私人教練。
            </p>

          </div>



          <div className="course-list">


            {selectedCourseData && (

              <div

                className={
                  selectedCoach ===
                  selectedCourseData.coachid
                    ? 'course-card selected'
                    : 'course-card'
                }

                onClick={() =>
                  setSelectedCoach(
                    selectedCourseData.coachid
                  )
                }

              >


                <div className="course-info">

                  <h4>
                    {
                      selectedCourseData.coachname
                    }
                  </h4>

                  <p>
                    課程：
                    {
                      selectedCourseData.coursename
                    }
                  </p>

                </div>



                <div className="coach-tag">
                  可預約教練
                </div>


              </div>

            )}


          </div>



          <div className="booking-summary">

            <div>

              <span>
                目前選擇課程：
              </span>

              <strong>

                {
                  selectedCourseData
                    ? selectedCourseData.coursename
                    : '尚未選擇'
                }

              </strong>

            </div>

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

              onClick={() =>
                setCurrentStep(3)
              }

              disabled={
                selectedCoach === null
              }

            >

              下一步

            </button>


          </div>


        </div>

      )}



      {/* =========================
          STEP 3 選擇日期
      ========================= */}

      {currentStep === 3 && (

        <div className="course-section">


          <div className="section-title">

            <h3>
              選擇日期
            </h3>

            <p>
              請選擇您想預約上課的日期。
            </p>

          </div>



          <div className="calendar-container">


            <Calendar

              onChange={date => {

                setSelectedDate(date)

                // 日期改變時清掉原本時段
                setSelectedTime(null)

                setScheduleOptions([])

              }}

              value={selectedDate}

              minDate={new Date()}

              tileDisabled={({ date }) => {

                const localDate =
                  date.toLocaleDateString(
                    'en-CA'
                  )

                if (
                  !Array.isArray(
                    availableDates
                  )
                ) {
                  return true
                }

                return !availableDates.includes(
                  localDate
                )

              }}

            />


          </div>



          <div className="booking-summary">


            <div>

              <span>
                課程：
              </span>

              <strong>

                {
                  selectedCourseData
                    ? selectedCourseData.coursename
                    : ''
                }

              </strong>

            </div>



            <div>

              <span>
                教練：
              </span>

              <strong>

                {
                  selectedCourseData
                    ? selectedCourseData.coachname
                    : ''
                }

              </strong>

            </div>



            <div>

              <span>
                日期：
              </span>

              <strong>

                {
                  selectedDate
                    .toLocaleDateString(
                      'zh-TW'
                    )
                }

              </strong>

            </div>


          </div>



          <div className="booking-actions">


            <button

              className="back-button"

              onClick={() =>
                setCurrentStep(2)
              }

            >

              上一步

            </button>



            <button

              className="next-button"

              onClick={() =>
                setCurrentStep(4)
              }

            >

              下一步

            </button>


          </div>


        </div>

      )}



      {/* =========================
          STEP 4 選擇時段
      ========================= */}

      {currentStep === 4 && (

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


            <div>

              <span>
                課程：
              </span>

              <strong>

                {
                  selectedCourseData
                    ? selectedCourseData.coursename
                    : ''
                }

              </strong>

            </div>



            <div>

              <span>
                教練：
              </span>

              <strong>

                {
                  selectedCourseData
                    ? selectedCourseData.coachname
                    : ''
                }

              </strong>

            </div>



            <div>

              <span>
                日期：
              </span>

              <strong>

                {
                  selectedDate
                    .toLocaleDateString(
                      'zh-TW'
                    )
                }

              </strong>

            </div>


          </div>



          <div className="time-list">


            {scheduleOptions.map(
              schedule => (

                <button

                  key={
                    schedule.scheduleid
                  }

				  className={
				    schedule.status === 'booked'
				      ? 'time-card disabled-time'
				      : selectedTime === schedule.scheduleid
				        ? 'time-card selected-time'
				        : 'time-card available-time'
				  }
					
				  
				  disabled={schedule.status === 'booked'}

				  
				  onClick={() => {
				      if (schedule.status === 'available') {
				        setSelectedTime(schedule.scheduleid)
				      }
				    }}
				  >


                  <strong>

                    {
                      schedule.starttime
                        .substring(0, 5)
                    }

                    {' - '}

                    {
                      schedule.endtime
                        .substring(0, 5)
                    }

                  </strong>


				  <span>
				    {schedule.status === 'booked'
				      ? '已被預約'
				      : '可預約'}
				  </span>


                </button>

              )
            )}


          </div>



          <div className="booking-summary">

            <div>

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

          </div>



          <div className="booking-actions">


            <button

              className="back-button"

              onClick={() =>
                setCurrentStep(3)
              }

              disabled={isBooking}

            >

              上一步

            </button>



            <button

              className="next-button"

              onClick={handleBooking}

              disabled={
                selectedTime === null ||
                isBooking
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



      {/* =========================
          STEP 5 預約完成
      ========================= */}

      {currentStep === 5 && (

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



          <div
            className="booking-summary final-summary"
          >


            <div>

              <span>
                課程：
              </span>

              <strong>

                {
                  selectedCourseData
                    ? selectedCourseData.coursename
                    : ''
                }

              </strong>

            </div>



            <div>

              <span>
                教練：
              </span>

              <strong>

                {
                  selectedCourseData
                    ? selectedCourseData.coachname
                    : ''
                }

              </strong>

            </div>



            <div>

              <span>
                日期：
              </span>

              <strong>

                {
                  selectedDate
                    .toLocaleDateString(
                      'zh-TW'
                    )
                }

              </strong>

            </div>



            <div>

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

  )

}


export default BookingCourse