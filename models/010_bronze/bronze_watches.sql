{{
  config(
    materialized = 'table',
    schema       = 'bronze',
    tags         = ['bronze', 'watches']
  )
}}

select
    watch_id,
    user_id,
    watch_date,
    watch_status,
    device,
    watching_country,
    completion_pct,
    created_at,

    current_timestamp()                                                           as _loaded_at,
    'seeds/raw_watches'                                                            as _source,
    {{ generate_record_hash(['watch_id', 'user_id', 'watch_date']) }}        as _row_hash

from {{ ref('raw_watches') }}
