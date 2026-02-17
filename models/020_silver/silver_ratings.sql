{{
  config(
    materialized = 'table',
    schema       = 'silver',
    tags         = ['silver', 'ratings']
  )
}}

with source as (
    select * from {{ ref('bronze_ratings') }}
),

cleaned as (
    select
        trim(rating_id)                       as rating_id,
        trim(watch_id)                        as watch_id,
        cast(show_id as int)                  as show_id,
        cast(user_rating as int)              as user_rating,
        trim(review_text)                     as review_text,

        -- derived column — flag for high ratings
        case when cast(user_rating as int) >= 4 
             then 'Positive' 
             else 'Neutral' 
        end                                   as rating_sentiment,

        cast(created_at as timestamp)         as created_at,
        _loaded_at,
        _source,
        _row_hash

    from source
    where rating_id is not null
      and user_rating >= 1 
      and user_rating <= 5
)

select * from cleaned
