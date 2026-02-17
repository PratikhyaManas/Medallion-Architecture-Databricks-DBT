{{
  config(
    materialized = 'table',
    schema       = 'bronze',
    tags         = ['bronze', 'ratings']
  )
}}

select
    rating_id,
    watch_id,
    show_id,
    user_rating,
    review_text,
    created_at,

    current_timestamp()                                                     as _loaded_at,
    'seeds/raw_ratings'                                                      as _source,
    {{ generate_record_hash(['rating_id', 'watch_id', 'show_id']) }}        as _row_hash

from {{ ref('raw_ratings') }}
