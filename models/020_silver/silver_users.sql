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
        case
          when {{ should_mask_pii() }} then concat('User_', cast(user_id as string))
          else initcap(trim(name))
        end                                   as name,
        case
          when {{ should_mask_pii() }} then null
          else nullif(trim(phone), '')
        end                                   as phone,
        case
          when {{ should_mask_pii() }} then {{ mask_email('lower(trim(email))') }}
          else lower(trim(email))
        end                                   as email,
        {{ tokenize_value('lower(trim(email))') }} as email_token,
        {{ tokenize_value('cast(user_id as string)') }} as user_token,
        case
          when {{ should_mask_pii() }} then null
          else trim(address)
        end                                   as address,
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
