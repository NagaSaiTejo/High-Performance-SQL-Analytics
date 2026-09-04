CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR UNIQUE,
    cohort_month DATE NOT NULL,
    referred_by INT REFERENCES users(user_id)
);

CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INT REFERENCES users(user_id),
    product_id INT NOT NULL,
    amount NUMERIC CHECK (amount > 0),
    status VARCHAR NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed users
INSERT INTO users (user_id, email, cohort_month, referred_by)
SELECT
    id,
    'user' || id || '@example.com',
    DATE_TRUNC('month', NOW() - (random() * 24 * 30 * interval '1 day'))::DATE,
    CASE 
        WHEN random() < 0.2 AND id > 1 THEN floor(random() * (id - 1))::INT + 1
        ELSE NULL 
    END
FROM generate_series(1, 200000) as id;

SELECT setval('users_user_id_seq', (SELECT MAX(user_id) FROM users));

-- Seed orders
INSERT INTO orders (user_id, product_id, amount, status, created_at)
SELECT
    floor(power(random(), 3) * 199999)::INT + 1,
    floor(random() * 1000)::INT + 1,
    (random() * 990 + 10)::NUMERIC(10, 2),
    (ARRAY['completed', 'completed', 'completed', 'pending', 'cancelled'])[floor(random() * 5) + 1],
    NOW() - (random() * 730 * interval '1 day')
FROM generate_series(1, 1000000);
