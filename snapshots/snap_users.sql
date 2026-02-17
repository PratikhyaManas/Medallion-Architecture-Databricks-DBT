{% snapshot snap_users %}
{{
  config(
    unique_key  = 'user_id',
    schema      = 'silver',
    strategy    = 'check',
    check_cols  = ['name','phone','email','address','region','postal_zip','country']
  )
}}

select
    user_id,
    name,
    phone,
    email,
    address,
    region,
    postal_zip,
    country,
    subscription_date

from {{ ref('silver_users') }}

{% endsnapshot %}
