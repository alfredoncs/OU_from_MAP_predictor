-- Again...I am using JC example.
-- we gonna need both: fluid balance per bloc and also de urine output: in this case I think that urine output is a kind of output in the string: "case when cellpath like '%Output%' then cellvaluenumeric else 0 end as voloutput"
-- for fluid balance calculation we can just follow JC query, but to fin specifically urine output we need to look inside of cellpath like '%Output%'...the option urine output should be there!

create table public.eicu2io as
(

with t1 as
(

select distinct pt.patientunitstayid, intakeoutputoffset, floor(intakeoutputoffset/240)+1 as bloc,
case when cellpath like '%Intake%' then cellvaluenumeric else 0 end as volinput,
case when cellpath like '%Intake%' and cellpath like any ('{%0.2%,%.2ns%,%.2 ns%}') then cellvaluenumeric*0.25
when cellpath like '%Intake%' and cellpath like any ('{%/50 meq nah%,%bicarbonate 50%}') then cellvaluenumeric *0.8
when cellpath like '%Intake%' and cellpath like any ('{%150 meq nah%,%bicarbonate 150%}') then cellvaluenumeric *1.5
when cellpath like '%Intake%' and cellpath like any ('{%.45%}') then cellvaluenumeric *0.5 -- needs to come after nah !
when cellpath like '%Intake%' and cellpath like any ('{%3\%%,%mannitol%}') then cellvaluenumeric * 3
when cellpath like '%Intake%' and cellpath like any ('{%25\%%}') then cellvaluenumeric * 5
when cellpath like '%Intake%' then cellvaluenumeric else 0 end as volinput_tev,
case when cellpath like '%Output%' then cellvaluenumeric else 0 end as voloutput,
case when cellpath like '%Dialysis%' then cellvaluenumeric else 0 end as voldialysis -- cellvaluenumeric is always POSITIVE , DIALYSIStotal is NEGATIVE for fluid removal from RRT
-- many items for dialysis are actually labelled 'OUTPUT' and not 'DIALYSIS'
from public.cohort7 pt
left outer join eicu.intakeoutput
on pt.patientunitstayid=intakeoutput.patientunitstayid
where cellpath in  (select cellpath from public.eicuiogoodlabels)
and intakeoutputoffset between 0 and 432 0
-- order by pt.patientunitstayid, intakeoutputoffset

)

select patientunitstayid, bloc, sum(volinput) as input_4hourly, sum(volinput_tev) as input_4hourly_tev, sum(voloutput + voldialysis) as output_4hourly, sum(volinput - voloutput - voldialysis) as fb_4hourly, sum(volinput_tev - voloutput - voldialysis) as fb_4hourly_tev
from t1
group by patientunitstayid, bloc


);
