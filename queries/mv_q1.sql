CREATE MATERIALIZED VIEW daily_revenue_stats AS
WITH daily_rev AS (
    SELECT 
        created_at::DATE AS day,
        SUM(amount) AS daily_revenue
    FROM orders
    GROUP BY 1
),
rolling_calc AS (
    SELECT 
        day,
        daily_revenue,
        AVG(daily_revenue) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7d_avg
    FROM daily_rev
)
SELECT 
    day,
    ROUND(daily_revenue, 2) AS daily_revenue,
    ROUND(rolling_7d_avg, 2) AS rolling_7d_avg
FROM rolling_calc
WHERE day >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY day;
