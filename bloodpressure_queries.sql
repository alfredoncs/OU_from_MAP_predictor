
-- There are two tables where we can find info about blood pressure: vitalperiodic and vitalaperiodic.
-- These tables are complementary to each other.The table vitalperidodic has info about invase measurements and vitalaperiodic about non invasive methods
-- In order to calcultae the mean arterial pressure we should do: MAP = 2x(diastolic pressure) + systolic pressure / 3



--From table vitalperiodic:

select patientunitstayid, systemicdiastolic as invasivediastolic, systemicsystolic as invasivesystolic
from eicu.vitalperiodic


-- From table vitalaperiodic:

select patientunitstayid, noninvasivediastolic, noninvasivesystolic
from eicu.vitalaperiodic 
