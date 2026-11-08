SELECT
    us_state,
    count() AS transaction_count,
    countIf(target = 1) AS fraud_count,
    round(100.0 * countIf(target = 1) / count(), 2) AS fraud_rate,
    uniqExact(customer_id) AS unique_customers,
    uniqExact(merch) AS unique_merchants,
    sum(amount) AS total_amount,
    sumIf(amount, target = 1) AS fraud_amount
FROM {{ ref('stg_transactions') }}
GROUP BY us_state
