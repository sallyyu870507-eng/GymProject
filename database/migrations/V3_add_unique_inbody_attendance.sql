USE gym
go 

ALTER TABLE inbodyrecords
ADD CONSTRAINT UQ_inbodyrecords_attendanceid
UNIQUE (attendanceid);