{% if target.name in ['dev', 'ci', 'qa', 'test'] %}

select name
from {{ ref('silver_users') }}
where name is not null
  and name not like 'User_%'

{% else %}

select 1
where false

{% endif %}
