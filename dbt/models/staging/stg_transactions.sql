WITH normalized_transactions AS (
    SELECT
        toDateTime(transaction_time) AS transaction_time,
        trimBoth(merch) AS merch,
        trimBoth(cat_id) AS cat_id,
        toFloat64(amount) AS amount,
        trimBoth(name_1) AS name_1,
        trimBoth(name_2) AS name_2,
        upperUTF8(trimBoth(gender)) AS gender,
        upperUTF8(trimBoth(us_state)) AS us_state,
        toFloat64(lat) AS lat,
        toFloat64(lon) AS lon,
        toFloat64(merchant_lat) AS merchant_lat,
        toFloat64(merchant_lon) AS merchant_lon,
        toUInt8(target) AS target
    FROM {{ source('transactions_db', 'transactions') }}
    WHERE transaction_time IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'transaction_time', 'merch', 'cat_id', 'amount', 'name_1', 'name_2',
        'gender', 'us_state', 'lat', 'lon', 'merchant_lat', 'merchant_lon', 'target'
    ]) }} AS transaction_id,
    transaction_time,
    toDate(transaction_time) AS transaction_date,
    toHour(transaction_time) AS transaction_hour,
    {{ dbt_date.day_of_week('transaction_time') }} AS day_of_week,
    merch,
    cat_id,
    amount,
    {{ dbt_utils.generate_surrogate_key([
    'lowerUTF8(name_1)', 'lowerUTF8(name_2)'
    ]) }} AS customer_id,
    name_1,
    name_2,
    gender,
    us_state,
    lat,
    lon,
    merchant_lat,
    merchant_lon,
    target,
    {{ amount_bucket('amount') }} AS amount_bucket
FROM normalized_transactions
