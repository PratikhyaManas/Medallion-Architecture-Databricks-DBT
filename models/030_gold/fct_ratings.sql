{{
  config(
    materialized = 'table',
    schema       = 'gold',
    tags         = ['gold', 'fact', 'ratings'],
    description  = 'Fact table for user ratings enriched with show, watch, and user context',
    indexes      = [
      {"columns": ["rating_date"], "type": "sorted"},
      {"columns": ["user_id"], "type": "sorted"}
    ]
  )
}}

select
    r.rating_id,
    r.watch_id,
    r.show_id,
    r.user_rating,
    r.review_text,
    r.rating_sentiment,

    -- watch context
    w.user_id,
    w.watch_date,
    w.watch_status,
    w.device,
    w.watching_country,
    w.completion_pct,

    -- show enrichment from gold dimension
    s.show_name,
    s.genre,
    s.quality_tier,
    s.series_length,
    s.rating_avg

from {{ ref('silver_ratings') }} r
left join {{ ref('silver_watches') }} w using (watch_id)
left join {{ ref('dim_shows') }} s using (show_id)
