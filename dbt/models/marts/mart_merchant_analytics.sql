SELECT
    merch,
    count() AS transaction_count,
    countIf(target = 1) AS fraud_count,
    round(100.0 * countIf(target = 1) / count(), 2) AS fraud_rate,
    sum(amount) AS total_amount,
    sumIf(amount, target = 1) AS fraud_amount,
    avg(amount) AS average_amount,
    if(
        countIf(target = 1) >= {{ var('suspicious_merchant_min_frauds', 3) }}
        AND 100.0 * countIf(target = 1) / count() >= {{ var('high_fraud_rate', 5) }},
        1,
        0
    ) AS is_suspicious
FROM {{ ref('stg_transactions') }}
GROUP BY merch
