{{
  config(
    materialized = 'table',
    schema       = 'gold',
    tags         = ['gold', 'fact', 'watches'],
    description  = 'Fact table for viewing sessions with rating metrics and time dimensions',
    indexes      = [
      {"columns": ["watch_date"], "type": "sorted"},
      {"columns": ["user_id"], "type": "sorted"}
    ]
  )
}}

with watches as (
    select * from {{ ref('silver_watches') }}
),

ratings_agg as (
    select
        watch_id,
        count(*)          as rating_count,
        avg(user_rating)  as avg_rating,
        max(user_rating)  as max_rating
    from {{ ref('silver_ratings') }}
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
        dayofweek(w.watch_date)                             as watch_day_of_week

    from watches w
    left join ratings_agg r using (watch_id)
)

select * from final
