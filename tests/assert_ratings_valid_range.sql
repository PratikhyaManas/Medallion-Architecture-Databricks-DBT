-- Fail if any silver_ratings row has invalid rating
select *
from {{ ref('silver_ratings') }}
where user_rating < 1
   or user_rating > 5
