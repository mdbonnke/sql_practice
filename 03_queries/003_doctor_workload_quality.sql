set search_path to sqlgym;

/*
  Drill: Doctor Load + Active Burden (Intermediate Pressure)
  
Scenario

>>>>Hospital management wants to evaluate doctor workload quality, not just volume.

They care about:

	Total admissions handled

	How many are still active (not discharged)

	Whether the doctor is overloaded

Schema

>>>admissions(admission_id, patient_id, doctor_id, ward, admitted_at, discharged_at)

>>>doctors(doctor_id, full_name, specialty)

Goal

Return:

| doctor_name | specialty | total_admissions | active_admissions | workload_level |

Logic Requirements

	total_admissions → all admissions per doctor

	active_admissions → where discharged_at IS NULL

	workload_level:
		
		'Overloaded' → active_admissions > 5
		
		'Moderate' → active_admissions between 3–5
		
		'Light' → otherwise

Constraints

	Must use JOIN
	
	Must use CASE
	
	Must use conditional aggregation (no subqueries)
	
	Order by:
		
		active_admissions DESC
		
		doctor_name ASC

Expected Output (example)
doctor_name	specialty	total_admissions	active_admissions	workload_level
Dr. A	Surgery	12	6	Overloaded
Dr. B	Medicine	8	4	Moderate
Dr. C	Pediatrics	3	1	Light	

What is being tested

	Whether you separate metrics correctly
	
	Whether you understand NULL vs non-NULL counting
	
	Whether you translate business logic into SQL

Hidden trap

If you:
	
	use count(discharged_at) incorrectly again → wrong active counts
	
	misuse CASE thresholds → wrong classification
	
	forget grouping columns → query breaks
 */
select 
	d.full_name as doctor_name,
	d.specialty,
	count(*) as total_admissions,
	count(*) filter (where a.discharged_at is null) as active_admissions,
	case
		when count(*) filter (where a.discharged_at is null) > 5 then 'Overloaded'
		when count(*) filter (where a.discharged_at is null) between 3 and 5 then 'Moderate'
		else 'Light'
	end as workload_level
	
from admissions a
join doctors d
on
a.doctor_id = d.doctor_id
group by
d.full_name,
d.specialty
order by
active_admissions desc,
doctor_name asc;