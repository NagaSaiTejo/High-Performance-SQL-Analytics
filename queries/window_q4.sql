WITH user_activity AS (
    SELECT DISTINCT user_id 
    FROM orders 
    WHERE created_at >= CURRENT_DATE - INTERVAL '60 days'
),
all_periods AS (
    SELECT user_id, 1 AS period FROM user_activity
    UNION ALL
    SELECT user_id, 2 AS period FROM user_activity
),
period_counts AS (
    SELECT 
        ap.user_id,
        ap.period,
        COUNT(o.order_id) AS order_count
    FROM all_periods ap
    LEFT JOIN orders o 
        ON ap.user_id = o.user_id 
        AND (
            (ap.period = 1 AND o.created_at >= CURRENT_DATE - INTERVAL '30 days') OR
            (ap.period = 2 AND o.created_at >= CURRENT_DATE - INTERVAL '60 days' AND o.created_at < CURRENT_DATE - INTERVAL '30 days')
        )
    GROUP BY ap.user_id, ap.period
),
lagged AS (
    SELECT 
        user_id,
        period,
        order_count,
        LAG(order_count) OVER (PARTITION BY user_id ORDER BY period DESC) as prev_count
    FROM period_counts
)
SELECT 
    user_id,
    order_count::INT AS orders_last_30d,
    prev_count::INT AS orders_prev_30d
FROM lagged
WHERE period = 1 AND order_count < prev_count
ORDER BY user_id;
