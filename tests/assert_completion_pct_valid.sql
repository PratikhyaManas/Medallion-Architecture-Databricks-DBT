-- Completion percentage must be between 0 and 1
select watch_id, completion_pct
from {{ ref('fct_watches') }}
where completion_pct < 0 
   or completion_pct > 1.0
