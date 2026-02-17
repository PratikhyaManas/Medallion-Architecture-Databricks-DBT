-- Every completed watch must have at least one rating
select w.watch_id
from   {{ ref('silver_watches') }}      w
left join {{ ref('silver_ratings') }} r using (watch_id)
where  w.watch_status = 'completed'
  and  r.rating_id is null
