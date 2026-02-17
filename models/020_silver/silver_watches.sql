{{
  config(
    materialized = 'table',
    schema       = 'silver',
    tags         = ['silver', 'watches'],
    description  = 'Cleaned viewing sessions with normalized status and validated completion percentage',
    columns      = {
      'watch_id': {'description': 'Unique viewing session identifier'},
      'user_id': {'description': 'Foreign key to user'},
      'watch_date': {'description': 'Date of viewing session'},
      'watch_status': {'description': 'Status: completed|paused|dropped|in_progress'},
      'completion_pct': {'description': 'Percentage watched (0-1)'}
    }
  )
}}

with source as (
    select * from {{ ref('bronze_watches') }}
),

cleaned as (
    select
        watch_id,
        cast(user_id as int)                  as user_id,
        cast(watch_date as date)              as watch_date,
        lower(watch_status)                   as watch_status,
        device,
        upper(watching_country)               as watching_country,
        cast(completion_pct as decimal(5,2))  as completion_pct,
        cast(created_at as timestamp)         as created_at,
        _loaded_at,
        _source,
        _row_hash

    from source
    where watch_id is not null
      and user_id is not null
      and watch_status not in ('test', 'dummy', 'sample')
)

select * from cleaned
