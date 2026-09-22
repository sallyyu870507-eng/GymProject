USE GymProject;
GO

create table classschedule(
	scheduleid INT IDENTITY(1,1) PRIMARY KEY,
	/*從1開始每新增1筆就自動加1*/

	coachid INT NOT NULL,
	courseid INT NOT NULL,

	classdate DATE NOT NULL,
	starttime TIME NOT NULL,
	endtime TIME NOT NULL,

	classroom VARCHAR(50) NULL,

	[status] VARCHAR(50) NOT NULL
		CONSTRAINT df_classschedule_status
		DEFAULT 'available',

	CONSTRAINT fk_classschedule_coach
	/*確認教練從外表而來*/
		FOREIGN KEY (coachid)
		REFERENCES coach(coachid),

	CONSTRAINT fk_classschedule_course
	/*確認課程從外表而來*/
		FOREIGN KEY (courseid)
		REFERENCES course(courseid),

	CONSTRAINT uq_classschedule_coach_datetime
	/*確認教練時間不可重複*/
		UNIQUE(coachid, classdate, starttime),

	CONSTRAINT ck_classschedule_one_hour
	/*確認時間是否為差1小時*/
		CHECK(
			DATEDIFF(MINUTE, starttime, endtime)=60
		),

	CONSTRAINT ck_classschedule_status
	/*狀態只能使用指定文字*/
		CHECK(
			[status]IN('available','unavailable','closed')
		)

);
GO