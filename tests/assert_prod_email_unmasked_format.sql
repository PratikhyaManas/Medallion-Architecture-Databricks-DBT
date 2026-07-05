{% if target.name == 'prod' %}

select email
from {{ ref('silver_users') }}
where email is not null
  and not (
    email rlike '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
    and email not like 'masked_%@example.invalid'
  )

{% else %}

select 1
where false

{% endif %}
