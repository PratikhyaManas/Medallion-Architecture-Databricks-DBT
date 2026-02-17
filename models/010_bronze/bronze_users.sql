{{
  config(
    materialized = 'table',
    schema       = 'bronze',
    tags         = ['bronze', 'users']
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
    subscription_date,

    -- medallion audit columns
    current_timestamp()                                              as _loaded_at,
    'seeds/raw_users'                                           as _source,
    {{ generate_record_hash(['user_id', 'name', 'email']) }}   as _row_hash

from {{ ref('raw_users') }}
