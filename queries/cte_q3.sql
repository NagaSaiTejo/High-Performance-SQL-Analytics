WITH first_orders AS (
    SELECT DISTINCT ON (user_id) 
        user_id, created_at AS first_order_date, amount AS first_order_amount
    FROM orders
    ORDER BY user_id, created_at ASC
),
last_orders AS (
    SELECT DISTINCT ON (user_id) 
        user_id, created_at AS last_order_date, amount AS last_order_amount
    FROM orders
    ORDER BY user_id, created_at DESC
),
combined AS (
    SELECT 
        user_id, 
        first_order_date, 
        NULL::TIMESTAMPTZ AS last_order_date,
        first_order_amount, 
        NULL::NUMERIC AS last_order_amount
    FROM first_orders
    UNION ALL
    SELECT 
        user_id, 
        NULL::TIMESTAMPTZ, 
        last_order_date, 
        NULL::NUMERIC, 
        last_order_amount
    FROM last_orders
)
SELECT 
    user_id,
    MAX(first_order_date) AS first_order_date,
    MAX(last_order_date) AS last_order_date,
    MAX(first_order_amount) AS first_order_amount,
    MAX(last_order_amount) AS last_order_amount
FROM combined
GROUP BY user_id
ORDER BY user_id;
