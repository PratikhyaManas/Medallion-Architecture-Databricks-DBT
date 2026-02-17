{{
  config(
    materialized = 'table',
    schema       = 'silver',
    tags         = ['silver', 'shows']
  )
}}

with source as (
    select * from {{ ref('bronze_shows') }}
),

cleaned as (
    select
        cast(show_id as int)                      as show_id,
        initcap(trim(show_name))                  as show_name,
        initcap(trim(genre))                      as genre,
        cast(release_date as date)                as release_date,
        cast(rating_avg as decimal(3,1))          as rating_avg,
        cast(total_episodes as int)               as total_episodes,
        trim(production_company)                  as production_company,
        cast(created_at as timestamp)             as created_at,
        _loaded_at,
        _source,
        _row_hash

    from source
    where show_id is not null
      and rating_avg > 0
)

select * from cleaned
