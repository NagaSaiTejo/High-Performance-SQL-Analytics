WITH RECURSIVE top_users AS (
    SELECT user_id
    FROM orders
    GROUP BY user_id
    ORDER BY COUNT(*) DESC
    LIMIT 100
),
referral_tree AS (
    SELECT 
        tu.user_id AS root_user_id,
        tu.user_id AS current_user_id,
        1 AS depth
    FROM top_users tu

    UNION ALL

    SELECT 
        rt.root_user_id,
        u.user_id AS current_user_id,
        rt.depth + 1 AS depth
    FROM referral_tree rt
    JOIN users u ON u.referred_by = rt.current_user_id
)
SELECT 
    root_user_id AS user_id,
    MAX(depth) AS chain_depth
FROM referral_tree
GROUP BY root_user_id
ORDER BY chain_depth DESC, user_id;
