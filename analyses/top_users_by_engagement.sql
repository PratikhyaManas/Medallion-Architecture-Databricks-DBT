-- Ad-hoc: top 10 users ranked by viewing engagement and ratings
select
    u.name               as user_name,
    u.region,
    u.country,
    count(distinct w.watch_id)    as total_watches,
    round(avg(w.completion_pct), 2) as avg_completion_pct,
    round(avg(w.avg_rating), 2)   as avg_show_rating,
    max(w.watch_date)             as last_watch_date

from {{ ref('silver_users') }}  u
join {{ ref('fct_watches') }}   w using (user_id)
where w.watch_status = 'completed'
group by 1, 2, 3
order by count(distinct w.watch_id) desc
limit 10
