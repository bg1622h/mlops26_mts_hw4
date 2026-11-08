WITH hourly_metrics AS (
    SELECT
        day_of_week,
        transaction_hour,
        count() AS transaction_count,
        countIf(target = 1) AS fraud_count,
        round(100.0 * countIf(target = 1) / count(), 2) AS fraud_rate,
        sum(amount) AS total_amount,
        avg(amount) AS average_amount
    FROM {{ ref('stg_transactions') }}
    GROUP BY
        day_of_week,
        transaction_hour
),

overall_rate AS (
    SELECT 100.0 * countIf(target = 1) / count() AS fraud_rate
    FROM {{ ref('stg_transactions') }}
)

SELECT
    hourly_metrics.*,
    overall_rate.fraud_rate AS overall_fraud_rate,
    if(
        100.0 * hourly_metrics.fraud_count / hourly_metrics.transaction_count
        > overall_rate.fraud_rate,
        1,
        0
    ) AS is_high_risk_window
FROM hourly_metrics
CROSS JOIN overall_rate
