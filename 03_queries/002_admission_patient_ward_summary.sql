SET search_path TO sqlgym;

WITH admission_base AS (
    SELECT
        a.admission_id,
        a.patient_id,
        a.doctor_id,
        a.ward,
        a.admitted_at,
        a.discharged_at,
        (a.discharged_at - a.admitted_at) AS length_of_stay
    FROM admissions a
),

patient_admission_stats AS (
    SELECT
        patient_id,
        COUNT(*) AS total_admissions
    FROM admissions
    GROUP BY patient_id
),

diagnosis_counts AS (
    SELECT
        admission_id,
        COUNT(*) AS diagnosis_count
    FROM diagnoses
    GROUP BY admission_id
),

ranked_admissions AS (
    SELECT
        ab.*,
        ROW_NUMBER() OVER (
            PARTITION BY ab.patient_id
            ORDER BY ab.admitted_at
        ) AS admission_sequence
    FROM admission_base ab
),

ward_volume AS (
    SELECT
        ward,
        COUNT(*) AS ward_total_admissions
    FROM admissions
    GROUP BY ward
),

ward_rank AS (
    SELECT
        ward,
        ward_total_admissions,
        RANK() OVER (
            ORDER BY ward_total_admissions DESC
        ) AS ward_rank
    FROM ward_volume
)

SELECT
    ra.admission_id,
    p.full_name AS patient_name,
    d.full_name AS doctor_name,
    ra.ward,
    ra.admitted_at,
    ra.discharged_at,
    ra.length_of_stay,

    -- patient-level stats
    pas.total_admissions,
    ra.admission_sequence,

    -- diagnosis info
    COALESCE(dc.diagnosis_count, 0) AS diagnosis_count,

    -- ward-level stats
    wr.ward_total_admissions,
    wr.ward_rank

FROM ranked_admissions ra

JOIN patients p
    ON ra.patient_id = p.patient_id

JOIN doctors d
    ON ra.doctor_id = d.doctor_id

LEFT JOIN patient_admission_stats pas
    ON ra.patient_id = pas.patient_id

LEFT JOIN diagnosis_counts dc
    ON ra.admission_id = dc.admission_id

LEFT JOIN ward_rank wr
    ON ra.ward = wr.ward

ORDER BY
    wr.ward_rank ASC,
    pas.total_admissions DESC,
    ra.admitted_at DESC;