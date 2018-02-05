---------------------------------------------------------------------------------------
-- Title: SQL Code extraction
-- Description:  Please read "read me" for details about inclusion and exclusion criteria 
-- SET search_path to eicu_crd,public;
-- ---------------------------------------------------------------------------------------



WITH t1 as
(
SELECT
    DISTINCT (p.patientunitstayid)
  , p.age
  , p.uniquepid, ROW_NUMBER() OVER (partition BY p.uniquepid ORDER BY  p.hospitaladmityear ASC) AS position
  , p.gender
  , case -- fixing age >89 to 93
                WHEN p.age LIKE '%89%' then '93' 
                ELSE p.age end AS age_fixed
  , p.admissionheight AS height
  , p.admissionweight AS weight
  , p.ethnicity
  , p.hospitaladmityear
  , p.hospitaladmitsource
  , p.unittype
  , p.unitadmitsource
  , p.unitdischargetime24
  , p.apacheadmissiondx
  , a.actualicumortality
  , a.actualhospitalmortality
  , s.readmit
  , p.hospitalid
  , s.readmit
  , h.numbedscategory
  , h.teachingstatus
  , h.region
  , a.unabridgedunitlos
  , a.unabridgedhosplos
  , a.unabridgedactualventdays
  , t.intubated AS intubated_first_24h
  , s.aids
  , s.hepaticfailure
  , s.lymphoma
  , s.metastaticcancer
  , s.leukemia
  , s.immunosuppression
  , s.cirrhosis
  , s.diabetes
  , s.electivesurgery
  , t.dialysis AS chronic_dialysis_prior_to_hospital
  , s.activetx
  , a.apachescore
  , (cv.sofa_cv+respi.sofa_respi+ renal.sofarenal+others.sofacoag+ others.sofaliver+others.sofacns) as sofatotal
  , ch.charlson_score
  , o.oasis
  , o.oasis_prob
FROM eicu_crd.patient p
LEFT JOIN eicu_crd.apachepredvar s
  ON  p.patientunitstayid =s.patientunitstayid
LEFT JOIN eicu_crd.apachepatientresult a
  ON p.patientunitstayid = a.patientunitstayid
LEFT JOIN eicu_crd.apacheapsvar t
  ON p.patientunitstayid = t.patientunitstayid
LEFT JOIN sofacv cv
  ON p.patientunitstayid = cv.patientunitstayid
LEFT JOIN sofarespi respi
  ON p.patientunitstayid = respi.patientunitstayid
LEFT JOIN sofarenal renal
  ON p.patientunitstayid = renal.patientunitstayid
LEFT JOIN sofa3others others
  ON p.patientunitstayid = others.patientunitstayid
LEFT JOIN charlson_score ch
  ON p.patientunitstayid = ch.patientunitstayid
LEFT JOIN oasis o
  ON p.patientunitstayid = o.patientunitstayid
LEFT JOIN eicu_crd.hospital h
  ON  p.hospitalid = h.hospitalid
WHERE p.apacheadmissiondx ILIKE '%sepsis%'
  AND s.readmit = 0
  AND p.age NOT IN ( '0', '1','2','3','4','5','6','7','8','9','10','11','12','13','14','15')
  AND a.actualicumortality IS NOT NULL
  AND p.admissionheight IS NOT NULL
  AND  p.admissionweight IS NOT  NULL
ORDER BY p.patientunitstayid
)
SELECT t1.*
FROM t1
WHERE position =1 --  first ICU admission
