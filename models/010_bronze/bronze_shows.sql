{{
  config(
    materialized = 'table',
    schema       = 'bronze',
    tags         = ['bronze', 'shows']
  )
}}

select
    show_id,
    show_name,
    genre,
    release_date,
    rating_avg,
    total_episodes,
    production_company,
    created_at,

    current_timestamp()                                             as _loaded_at,
    'seeds/raw_shows'                                            as _source,
    {{ generate_record_hash(['show_id', 'show_name', 'genre']) }} as _row_hash

from {{ ref('raw_shows') }}
