WITH user_totals AS (
    SELECT user_id, SUM(amount) AS total_spend
    FROM orders
    GROUP BY user_id
)
SELECT 
    o.order_id,
    o.user_id,
    ROUND(o.amount, 2) AS amount,
    ROUND((o.amount / u.total_spend) * 100, 2) AS lifetime_share_pct
FROM orders o
JOIN user_totals u ON o.user_id = u.user_id
ORDER BY o.user_id, o.order_id;
