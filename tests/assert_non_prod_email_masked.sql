{% if target.name in ['dev', 'ci', 'qa', 'test'] %}

select email
from {{ ref('silver_users') }}
where email is not null
  and email not like 'masked_%@example.invalid'

{% else %}

select 1
where false

{% endif %}
