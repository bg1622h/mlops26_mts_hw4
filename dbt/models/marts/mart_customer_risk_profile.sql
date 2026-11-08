WITH customer_metrics AS (
    SELECT
        customer_id,
        any(name_1) AS first_name,
        any(name_2) AS last_name,
        any(gender) AS gender,
        any(us_state) AS state,
        count() AS transaction_count,
        countIf(target = 1) AS fraud_count,
        round(100.0 * countIf(target = 1) / count(), 2) AS fraud_rate,
        sum(amount) AS total_amount,
        avg(amount) AS average_amount,
        min(transaction_time) AS first_transaction_time,
        max(transaction_time) AS last_transaction_time
    FROM {{ ref('stg_transactions') }}
    GROUP BY customer_id
)

SELECT
    *,
    multiIf(
        100.0 * fraud_count / transaction_count >= {{ var('high_fraud_rate', 5) }}
        OR fraud_count >= 3,
        'HIGH',
        fraud_count > 0,
        'MEDIUM',
        'LOW'
    ) AS risk_level
FROM customer_metrics
