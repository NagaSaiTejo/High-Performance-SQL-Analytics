WITH extremes AS (
    SELECT DISTINCT
        user_id,
        FIRST_VALUE(created_at) OVER w AS first_order_date,
        LAST_VALUE(created_at) OVER w AS last_order_date,
        FIRST_VALUE(amount) OVER w AS first_order_amount,
        LAST_VALUE(amount) OVER w AS last_order_amount
    FROM orders
    WINDOW w AS (
        PARTITION BY user_id 
        ORDER BY created_at 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )
)
SELECT * FROM extremes ORDER BY user_id;
