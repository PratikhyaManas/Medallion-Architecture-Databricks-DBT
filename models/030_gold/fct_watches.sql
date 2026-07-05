{{
  config(
    materialized = 'incremental',
    schema       = 'gold',
    unique_key   = 'watch_id',
    incremental_strategy = 'merge',
    on_schema_change = 'sync_all_columns',
    partition_by = ['watch_date'],
    tags         = ['gold', 'fact', 'watches'],
    description  = 'Fact table for viewing sessions with rating metrics and time dimensions',
    indexes      = [
      {"columns": ["watch_date"], "type": "sorted"},
      {"columns": ["user_id"], "type": "sorted"}
    ]
  )
}}

with watermark as (
  {% if is_incremental() %}
  select coalesce(max(last_modified_at), cast('1900-01-01' as timestamp)) as last_watermark
  from {{ this }}
  {% else %}
  select cast('1900-01-01' as timestamp) as last_watermark
  {% endif %}
),

changed_watch_ids as (
  select distinct w.watch_id
  from {{ ref('silver_watches') }} w
  cross join watermark m
  where w._loaded_at >= m.last_watermark

  union

  select distinct r.watch_id
  from {{ ref('silver_ratings') }} r
  cross join watermark m
  where r._loaded_at >= m.last_watermark
),

watches as (
  select w.*
  from {{ ref('silver_watches') }} w
  {% if is_incremental() %}
  inner join changed_watch_ids c
    on w.watch_id = c.watch_id
  {% endif %}
),

ratings_agg as (
    select
        watch_id,
        count(*)          as rating_count,
        avg(user_rating)  as avg_rating,
    max(user_rating)  as max_rating,
    max(_loaded_at)   as ratings_last_modified_at
    from {{ ref('silver_ratings') }}
  {% if is_incremental() %}
  where watch_id in (select watch_id from changed_watch_ids)
  {% endif %}
    group by watch_id
),

final as (
    select
        w.watch_id,
        w.user_id,
        w.watch_date,
        w.watch_status,
        w.device,
        w.watching_country,
        w.completion_pct,

        -- rating metrics
        coalesce(r.rating_count, 0)                         as rating_count,
        round(coalesce(r.avg_rating, 0), 2)                 as avg_rating,
        coalesce(r.max_rating, 0)                           as max_rating,

        -- time dimensions for BI slicing
        year(w.watch_date)                                  as watch_year,
        month(w.watch_date)                                 as watch_month,
        date_format(w.watch_date, 'yyyy-MM')                as watch_month_label,
        dayofweek(w.watch_date)                             as watch_day_of_week,
        greatest(w._loaded_at, coalesce(r.ratings_last_modified_at, w._loaded_at)) as last_modified_at

    from watches w
    left join ratings_agg r using (watch_id)
)

select * from final
