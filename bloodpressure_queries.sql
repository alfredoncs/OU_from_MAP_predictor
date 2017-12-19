
-- There are two tables where we can find info about blood pressure: vitalperiodic and vitalaperiodic.
-- These tables are complementary to each other.The table vitalperidodic has info about invase measurements and vitalaperiodic about non invasive methods
-- In order to calculate the mean arterial pressure we should do: MAP = 2x(diastolic pressure) + systolic pressure / 3
-- Also the third options is the one done by JC using nursingchart (please see his github repository: -https://github.com/matthieukomorowski/ICURL/blob/master/eICU_RI_extraction/data_extraction)


--From table vitalperiodic:

select patientunitstayid, systemicdiastolic as invasivediastolic, systemicsystolic as invasivesystolic
from eicu.vitalperiodic


-- From table vitalaperiodic:

select patientunitstayid, noninvasivediastolic, noninvasivesystolic
from eicu.vitalaperiodic 

-- JC suggestion using nursecharting table - note it is per bloc and include more than blood pressure, however it is helpful to understand
--Also read his full query in his github. there are plenty of good tips there!

## From nursecharting
## This occurs in several steps to speed up the process.

-- Step 1: extract raw values for vitals and BP

create table public.eicu2vitalsbpraw as
(

with tm1 as
(

with tm2 as
(
select pt.patientunitstayid, nursingchartoffset, nursingchartcelltypevalname, nursingchartvalue
from eicu.nursecharting
join public.cohort7 pt on cohort7.patientunitstayid = nursecharting.patientunitstayid
)
select * from tm2
where nursingchartcelltypevalname = any ('{Heart Rate,O2 Saturation,Respiratory Rate,Non-Invasive BP Systolic,Non-Invasive BP Diastolic,Non-Invasive BP Mean}') -- [OMAR: there are a lot of other non standard regex]


)

select * from tm1
where nursingchartvalue <> '' and nursingchartvalue ~  '^[0-9\/.]{1,8}$'
);


-- Step 2 = extract raw values per variable and compute time blocs

create table public.eicu2vitalsbpraw2 as
(

select patientunitstayid, floor(nursingchartoffset/240)+1 as bloc,
max(case when nursingchartcelltypevalname='Heart Rate' then nursingchartvalue else null end) as hr,
max(case when nursingchartcelltypevalname='O2 Saturation' and nursingchartvalue not like '%/%'  then nursingchartvalue else null end) as spo2,
max(case when nursingchartcelltypevalname='Respiratory Rate' then nursingchartvalue else null end) as rr,
max(case when nursingchartcelltypevalname='Non-Invasive BP Systolic' and nursingchartvalue like '%/%' then split_part(nursingchartvalue,'/',1)
when nursingchartcelltypevalname='Non-Invasive BP Systolic' then nursingchartvalue else null end) as sysbp,
max(case when nursingchartcelltypevalname='Non-Invasive BP Systolic' and nursingchartvalue like '%/%' then split_part(nursingchartvalue,'/',2)
when nursingchartcelltypevalname='Non-Invasive BP Diastolic'  then nursingchartvalue else null end) as diabp,
max(case when nursingchartcelltypevalname='Non-Invasive BP Mean'  then nursingchartvalue else null end) as meanbp
from public.eicu2vitalsbpraw
where nursingchartoffset between 0 and 4320 and nursingchartvalue ~  '^[0-9\/.]{1,8}$'
group by patientunitstayid, nursingchartoffset

);


-- Step 3 = compute average per bloc

create table public.eicu2vitalsbpnc as
(
select patientunitstayid, bloc,
round( avg(cast((hr) as numeric) ),2) as hr,
round( avg(cast((spo2) as numeric)) ,2) as spo2,
round( avg(cast((rr) as numeric)) ,2) as rr,
round( avg(cast((sysbp) as numeric)) ,2) as sbp,
round( avg(cast((diabp) as numeric)) ,2) as dbp,
round( avg(cast((meanbp) as numeric)) ,2) as mbp
from eicu2vitalsbpraw2
group by patientunitstayid, bloc
-- order by patientunitstayid, bloc
);
