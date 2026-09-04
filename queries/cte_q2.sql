WITH user_spend AS (
    SELECT 
        u.cohort_month,
        u.user_id,
        SUM(o.amount) AS total_spend
    FROM users u
    JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.cohort_month, u.user_id
),
cohorts AS (
    SELECT DISTINCT cohort_month FROM users
)
SELECT 
    c.cohort_month,
    t.user_id,
    ROUND(t.total_spend, 2) AS total_spend,
    (
        SELECT COUNT(*) + 1 
        FROM user_spend us2 
        WHERE us2.cohort_month = c.cohort_month 
          AND us2.total_spend > t.total_spend
    )::INT AS rank_in_cohort
FROM cohorts c
CROSS JOIN LATERAL (
    SELECT user_id, total_spend
    FROM user_spend us
    WHERE us.cohort_month = c.cohort_month
    ORDER BY total_spend DESC
    LIMIT 10
) t
ORDER BY c.cohort_month, rank_in_cohort;
