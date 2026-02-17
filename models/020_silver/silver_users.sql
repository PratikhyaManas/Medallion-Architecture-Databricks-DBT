{{
  config(
    materialized = 'table',
    schema       = 'silver',
    tags         = ['silver', 'users']
  )
}}

with source as (
    select * from {{ ref('bronze_users') }}
),

cleaned as (
    select
        cast(user_id as int)                  as user_id,
        initcap(trim(name))                   as name,
        nullif(trim(phone), '')               as phone,
        lower(trim(email))                    as email,
        trim(address)                         as address,
        trim(region)                          as region,
        trim(postal_zip)                      as postal_zip,
        upper(trim(country))                  as country,
        cast(subscription_date as timestamp)  as subscription_date,
        _loaded_at,
        _source,
        _row_hash

    from source
    where user_id is not null
      and name is not null
      and email is not null
)

select * from cleaned
