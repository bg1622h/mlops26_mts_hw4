SELECT
    transaction_date,
    us_state,
    count() AS transaction_count,
    sum(amount) AS total_amount,
    avg(amount) AS average_amount,
    quantileExact(0.95)(amount) AS p95_amount, -- noqa: AL03,PRS
    countIf(amount >= {{ var('large_transaction_amount', 1000) }}) AS large_transaction_count,
    round(100.0 * countIf(amount >= {{ var('large_transaction_amount', 1000) }}) / count(), 2) AS large_transaction_rate
FROM {{ ref('stg_transactions') }}
GROUP BY
    transaction_date,
    us_state
