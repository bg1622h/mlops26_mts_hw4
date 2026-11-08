SELECT
    cat_id,
    count() AS transaction_count,
    countIf(target = 1) AS fraud_count,
    round(100.0 * countIf(target = 1) / count(), 2) AS fraud_rate,
    sum(amount) AS total_amount,
    sumIf(amount, target = 1) AS fraud_amount,
    avg(amount) AS average_amount
FROM {{ ref('stg_transactions') }}
GROUP BY cat_id
