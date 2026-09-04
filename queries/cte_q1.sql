WITH daily_rev AS (
    SELECT 
        created_at::DATE AS day,
        SUM(amount) AS daily_revenue
    FROM orders
    GROUP BY 1
)
SELECT 
    d1.day,
    ROUND(d1.daily_revenue, 2) AS daily_revenue,
    ROUND(AVG(d2.daily_revenue), 2) AS rolling_7d_avg
FROM daily_rev d1
JOIN daily_rev d2 ON d2.day BETWEEN d1.day - INTERVAL '6 days' AND d1.day
WHERE d1.day >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY d1.day, d1.daily_revenue
ORDER BY d1.day;
