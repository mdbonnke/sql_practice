set search_path to sqlgym;

select 
    ward, 
    count(*) as total_admissions,
    sum(case when discharged_at is null then 1 else 0 end) as active_admissions,
    sum(case when discharged_at is not null then 1 else 0 end) as discharged_admissions
from admissions
group by ward
order by total_admissions desc, ward asc;