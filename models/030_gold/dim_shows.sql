{{
  config(
    materialized = 'table',
    schema       = 'gold',
    tags         = ['gold', 'dimension', 'shows'],
    description  = 'Dimension table for shows with quality tier and series length classifications',
    indexes      = [
      {"columns": ["show_id"], "type": "unique"}
    ]
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

    -- business-defined classifications
    case
        when rating_avg >= 4.7 then 'Masterpiece'
        when rating_avg >= 4.3 then 'Excellent'
        when rating_avg >= 4.0 then 'Great'
        else                        'Good'
    end as quality_tier,

    case
        when total_episodes >= 12 then 'Long-Running'
        when total_episodes >= 8  then 'Standard'
        else                        'Limited'
    end as series_length

from {{ ref('silver_shows') }}
