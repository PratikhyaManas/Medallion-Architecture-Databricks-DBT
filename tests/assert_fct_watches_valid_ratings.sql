-- No invalid ratings in fct_watches
select *
from {{ ref('fct_watches') }}
where avg_rating < 0
   or avg_rating > 5
   or max_rating > 5
