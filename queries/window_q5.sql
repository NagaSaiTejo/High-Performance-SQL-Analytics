SELECT 
    order_id,
    user_id,
    ROUND(amount, 2) AS amount,
    ROUND((amount / SUM(amount) OVER (PARTITION BY user_id)) * 100, 2) AS lifetime_share_pct
FROM orders
ORDER BY user_id, order_id;
