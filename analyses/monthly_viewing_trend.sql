-- Ad-hoc: monthly viewing trends with running total
select
    watch_month_label,
    count(distinct watch_id)    as watch_sessions,
    count(distinct user_id)     as unique_viewers,
    round(avg(completion_pct), 2) as avg_completion_pct,
    round(avg(avg_rating), 2)   as avg_show_rating,
    round(
        count(distinct watch_id) over (
            order by watch_month_label
            rows between unbounded preceding and current row
        )
    )                           as cumulative_watches

from {{ ref('fct_watches') }}
where watch_status = 'completed'
group by 1
order by 1
