SELECT *
FROM {{ ref('mart_hourly_fraud_pattern') }}
WHERE
    day_of_week NOT BETWEEN 1 AND 7
    OR transaction_hour NOT BETWEEN 0 AND 23
    OR fraud_rate NOT BETWEEN 0 AND 100
