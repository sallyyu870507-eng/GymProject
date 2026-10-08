
﻿USE [gym]
GO
/****** 物件:  Table [dbo].[attendance]    指令碼日期: 2026/9/23 下午 08:12:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[attendance](
	[attendanceid] [int] IDENTITY(1,1) NOT NULL,
	[bookingid] [int] NOT NULL,
	[checkintime] [datetime] NULL,
	[attendancestatus] [nvarchar](50) NOT NULL,
	[workoutfocus] [nvarchar](50) NULL,
	[note] [nvarchar](100) NULL,
 CONSTRAINT [PK_attendance] PRIMARY KEY CLUSTERED 
(
	[attendanceid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** 物件:  Table [dbo].[booking]    指令碼日期: 2026/9/23 下午 08:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[booking](
	[bookingid] [int] IDENTITY(1,1) NOT NULL,
	[membercourseid] [int] NOT NULL,
	[scheduleid] [int] NOT NULL,
	[bookingtime] [datetime] NOT NULL,
	[bookingstatus] [nvarchar](20) NOT NULL,
	[note] [nvarchar](100) NOT NULL,
	[updatetime] [datetime] NOT NULL,
 CONSTRAINT [PK_booking] PRIMARY KEY CLUSTERED 
(
	[bookingid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** 物件:  Table [dbo].[classschedule]    指令碼日期: 2026/9/23 下午 08:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[classschedule](
	[scheduleid] [int] IDENTITY(1,1) NOT NULL,
	[coachid] [int] NOT NULL,
	[courseid] [int] NOT NULL,
	[classdate] [date] NOT NULL,
	[starttime] [time](0) NOT NULL,
	[endtime] [time](0) NOT NULL,
	[classroom] [nvarchar](50) NOT NULL,
	[status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_classschedule] PRIMARY KEY CLUSTERED 
(
	[scheduleid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** 物件:  Table [dbo].[coach]    指令碼日期: 2026/9/23 下午 08:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[coach](
	[coachid] [int] IDENTITY(1,1) NOT NULL,
	[accountid] [int] NOT NULL,
	[coachno] [nvarchar](20) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[gender] [nvarchar](10) NOT NULL,
	[phone] [nvarchar](50) NOT NULL,
	[email] [nvarchar](100) NOT NULL,
	[specialty] [nvarchar](100) NOT NULL,
	[status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_coach] PRIMARY KEY CLUSTERED 
(
	[coachid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** 物件:  Table [dbo].[coachcourse]    指令碼日期: 2026/9/23 下午 08:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[coachcourse](
	[coachid] [int] NOT NULL,
	[courseid] [int] NOT NULL,
 CONSTRAINT [PK_coachcourse] PRIMARY KEY CLUSTERED 
(
	[coachid] ASC,
	[courseid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** 物件:  Table [dbo].[course]    指令碼日期: 2026/9/23 下午 08:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[course](
	[courseid] [int] IDENTITY(1,1) NOT NULL,
	[coursename] [nvarchar](100) NOT NULL,
	[coursetype] [nvarchar](50) NOT NULL,
	[description] [text] NOT NULL,
	[durationmin] [int] NOT NULL,
	[price] [int] NOT NULL,
	[status] [nchar](10) NOT NULL,
 CONSTRAINT [PK_course] PRIMARY KEY CLUSTERED 
(
	[courseid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** 物件:  Table [dbo].[followup]    指令碼日期: 2026/9/23 下午 08:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[followup](
	[followupid] [int] IDENTITY(1,1) NOT NULL,
	[membercourseid] [int] NOT NULL,
	[coachid] [int] NOT NULL,
	[status] [nvarchar](20) NULL,
	[urgencytag] [nvarchar](50) NULL,
	[note] [text] NULL,
	[createdat] [datetime] NULL,
 CONSTRAINT [PK_followup] PRIMARY KEY CLUSTERED 
(
	[followupid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** 物件:  Table [dbo].[inbodyrecords]    指令碼日期: 2026/9/23 下午 08:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[inbodyrecords](
	[inbodyid] [int] IDENTITY(1,1) NOT NULL,
	[memberid] [int] NOT NULL,
	[recorddate] [date] NULL,
	[weight] [decimal](5, 2) NULL,
	[bodyfatpct] [decimal](4, 1) NULL,
	[musclemass] [decimal](4, 1) NULL,
 CONSTRAINT [PK_inbodyrecords] PRIMARY KEY CLUSTERED 
(
	[inbodyid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** 物件:  Table [dbo].[member]    指令碼日期: 2026/9/23 下午 08:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[member](
	[memberid] [int] IDENTITY(1,1) NOT NULL,
	[accountid] [int] NOT NULL,
	[memberno] [nvarchar](20) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[gender] [nvarchar](10) NOT NULL,
	[phone] [nvarchar](50) NOT NULL,
	[email] [nvarchar](100) NOT NULL,
	[birthday] [date] NOT NULL,
	[status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_member] PRIMARY KEY CLUSTERED 
(
	[memberid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** 物件:  Table [dbo].[membercourse]    指令碼日期: 2026/9/23 下午 08:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[membercourse](
	[membercourseid] [int] IDENTITY(1,1) NOT NULL,
	[memberid] [int] NOT NULL,
	[courseid] [int] NOT NULL,
	[purchasedate] [date] NOT NULL,
	[totalsessions] [int] NOT NULL,
	[remainingsessions] [int] NOT NULL,
	[status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_membercourse] PRIMARY KEY CLUSTERED 
(
	[membercourseid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** 物件:  Table [dbo].[renewal]    指令碼日期: 2026/9/23 下午 08:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[renewal](
	[renewalid] [int] IDENTITY(1,1) NOT NULL,
	[membercourseid] [int] NOT NULL,
	[renewaldate] [datetime] NULL,
	[addedsessions] [int] NULL,
	[amount] [int] NULL,
	[paymentmethod] [nvarchar](50) NULL,
 CONSTRAINT [PK_renewal] PRIMARY KEY CLUSTERED 
(
	[renewalid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** 物件:  Table [dbo].[useraccount]    指令碼日期: 2026/9/23 下午 08:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[useraccount](
	[accountid] [int] IDENTITY(1,1) NOT NULL,
	[username] [nvarchar](50) NOT NULL,
	[password] [nvarchar](200) NOT NULL,
	[role] [nvarchar](50) NOT NULL,
	[status] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_useraccount_1] PRIMARY KEY CLUSTERED 
(
	[accountid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[attendance] ADD  CONSTRAINT [DF_attendance_attendancestatus]  DEFAULT (N'pending') FOR [attendancestatus]
GO
ALTER TABLE [dbo].[classschedule] ADD  CONSTRAINT [DF_classschedule_status]  DEFAULT (N'open') FOR [status]
GO
ALTER TABLE [dbo].[coach] ADD  CONSTRAINT [DF_coach_status]  DEFAULT (N'active') FOR [status]
GO
ALTER TABLE [dbo].[member] ADD  CONSTRAINT [DF_member_status]  DEFAULT (N'active') FOR [status]
GO
ALTER TABLE [dbo].[membercourse] ADD  CONSTRAINT [DF_membercourse_status]  DEFAULT (N'active') FOR [status]
GO
ALTER TABLE [dbo].[useraccount] ADD  CONSTRAINT [DF_useraccount_status]  DEFAULT (N'active') FOR [status]
GO
ALTER TABLE [dbo].[attendance]  WITH CHECK ADD  CONSTRAINT [FK_attendance_booking] FOREIGN KEY([bookingid])
REFERENCES [dbo].[booking] ([bookingid])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[attendance] CHECK CONSTRAINT [FK_attendance_booking]
GO
ALTER TABLE [dbo].[booking]  WITH CHECK ADD  CONSTRAINT [FK_booking_classschedule] FOREIGN KEY([scheduleid])
REFERENCES [dbo].[classschedule] ([scheduleid])
GO
ALTER TABLE [dbo].[booking] CHECK CONSTRAINT [FK_booking_classschedule]
GO
ALTER TABLE [dbo].[booking]  WITH CHECK ADD  CONSTRAINT [FK_booking_membercourse] FOREIGN KEY([membercourseid])
REFERENCES [dbo].[membercourse] ([membercourseid])
GO
ALTER TABLE [dbo].[booking] CHECK CONSTRAINT [FK_booking_membercourse]
GO
ALTER TABLE [dbo].[classschedule]  WITH CHECK ADD  CONSTRAINT [FK_classschedule_coach] FOREIGN KEY([coachid])
REFERENCES [dbo].[coach] ([coachid])
GO
ALTER TABLE [dbo].[classschedule] CHECK CONSTRAINT [FK_classschedule_coach]
GO
ALTER TABLE [dbo].[classschedule]  WITH CHECK ADD  CONSTRAINT [FK_classschedule_course] FOREIGN KEY([courseid])
REFERENCES [dbo].[course] ([courseid])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[classschedule] CHECK CONSTRAINT [FK_classschedule_course]
GO
ALTER TABLE [dbo].[coach]  WITH CHECK ADD  CONSTRAINT [FK_coach_useraccount] FOREIGN KEY([accountid])
REFERENCES [dbo].[useraccount] ([accountid])
GO
ALTER TABLE [dbo].[coach] CHECK CONSTRAINT [FK_coach_useraccount]
GO
ALTER TABLE [dbo].[coachcourse]  WITH CHECK ADD  CONSTRAINT [FK_coachcourse_coach] FOREIGN KEY([coachid])
REFERENCES [dbo].[coach] ([coachid])
GO
ALTER TABLE [dbo].[coachcourse] CHECK CONSTRAINT [FK_coachcourse_coach]
GO
ALTER TABLE [dbo].[coachcourse]  WITH CHECK ADD  CONSTRAINT [FK_coachcourse_course] FOREIGN KEY([courseid])
REFERENCES [dbo].[course] ([courseid])
GO
ALTER TABLE [dbo].[coachcourse] CHECK CONSTRAINT [FK_coachcourse_course]
GO
ALTER TABLE [dbo].[followup]  WITH CHECK ADD  CONSTRAINT [FK_followup_coach] FOREIGN KEY([coachid])
REFERENCES [dbo].[coach] ([coachid])
GO
ALTER TABLE [dbo].[followup] CHECK CONSTRAINT [FK_followup_coach]
GO
ALTER TABLE [dbo].[followup]  WITH CHECK ADD  CONSTRAINT [FK_followup_membercourse] FOREIGN KEY([membercourseid])
REFERENCES [dbo].[membercourse] ([membercourseid])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[followup] CHECK CONSTRAINT [FK_followup_membercourse]
GO
ALTER TABLE [dbo].[inbodyrecords]  WITH CHECK ADD  CONSTRAINT [FK_inbody_member] FOREIGN KEY([memberid])
REFERENCES [dbo].[member] ([memberid])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[inbodyrecords] CHECK CONSTRAINT [FK_inbody_member]
GO
ALTER TABLE [dbo].[member]  WITH CHECK ADD  CONSTRAINT [FK_member_useracoount] FOREIGN KEY([accountid])
REFERENCES [dbo].[useraccount] ([accountid])
GO
ALTER TABLE [dbo].[member] CHECK CONSTRAINT [FK_member_useracoount]
GO
ALTER TABLE [dbo].[membercourse]  WITH CHECK ADD  CONSTRAINT [FK_membercourse_course] FOREIGN KEY([courseid])
REFERENCES [dbo].[course] ([courseid])
GO
ALTER TABLE [dbo].[membercourse] CHECK CONSTRAINT [FK_membercourse_course]
GO
ALTER TABLE [dbo].[membercourse]  WITH CHECK ADD  CONSTRAINT [FK_membercourse_member] FOREIGN KEY([memberid])
REFERENCES [dbo].[member] ([memberid])
GO
ALTER TABLE [dbo].[membercourse] CHECK CONSTRAINT [FK_membercourse_member]
GO
ALTER TABLE [dbo].[renewal]  WITH CHECK ADD  CONSTRAINT [FK_renewal_membercourse] FOREIGN KEY([membercourseid])
REFERENCES [dbo].[membercourse] ([membercourseid])
GO
ALTER TABLE [dbo].[renewal] CHECK CONSTRAINT [FK_renewal_membercourse]
GO
