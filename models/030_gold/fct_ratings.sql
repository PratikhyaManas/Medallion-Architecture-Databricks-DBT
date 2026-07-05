{{
  config(
    materialized = 'incremental',
    schema       = 'gold',
    unique_key   = 'rating_id',
    incremental_strategy = 'merge',
    on_schema_change = 'sync_all_columns',
    partition_by = ['rating_date'],
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
  r.review_text as rating_review,
    r.rating_sentiment,
  cast(r.created_at as date) as rating_date,

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
    s.rating_avg,
    r._loaded_at as last_modified_at

from {{ ref('silver_ratings') }} r
left join {{ ref('silver_watches') }} w using (watch_id)
left join {{ ref('dim_shows') }} s using (show_id)

  {% if is_incremental() %}
  where r._loaded_at >= (
    select coalesce(max(last_modified_at), cast('1900-01-01' as timestamp))
    from {{ this }}
  )
  {% endif %}
