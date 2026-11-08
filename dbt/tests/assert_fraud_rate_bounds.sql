SELECT
    'mart_fraud_by_category' AS model_name,
    cat_id AS dimension,
    fraud_rate
FROM {{ ref('mart_fraud_by_category') }}
WHERE fraud_rate < 0 OR fraud_rate > 100

UNION ALL

SELECT
    'mart_fraud_by_state' AS model_name,
    us_state AS dimension,
    fraud_rate
FROM {{ ref('mart_fraud_by_state') }}
WHERE fraud_rate < 0 OR fraud_rate > 100
