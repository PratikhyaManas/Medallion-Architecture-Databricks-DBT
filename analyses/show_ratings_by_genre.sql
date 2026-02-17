-- Ad-hoc: average rating and viewer engagement by show genre
select
    genre,
    quality_tier,
    count(distinct show_id)       as num_shows,
    count(distinct watch_id)      as total_views,
    round(avg(user_rating), 2)    as avg_user_rating,
    round(
        100.0 * count(distinct watch_id)
      / sum(count(distinct watch_id)) over (),
    2)                            as views_share_pct

from {{ ref('fct_ratings') }}
where watch_status = 'completed'
group by 1, 2
order by avg_user_rating desc
