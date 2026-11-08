CREATE DATABASE IF NOT EXISTS transactions_db;
CREATE DATABASE IF NOT EXISTS transactions_dbt;

CREATE TABLE IF NOT EXISTS transactions_db.transaction_queue
(
    transaction_time DateTime,
    merch            String,
    cat_id           String,
    amount           Float64,
    name_1           String,
    name_2           String,
    gender           String,
    us_state         String,
    lat              Float64,
    lon              Float64,
    merchant_lat     Float64,
    merchant_lon     Float64,
    target           UInt8
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'transactions_dbt',
    kafka_group_name = 'clickhouse_dbt_transactions_group',
    kafka_format = 'JSONEachRow',
    kafka_num_consumers = 1;

CREATE TABLE IF NOT EXISTS transactions_db.transactions
(
    transaction_time DateTime,
    merch            LowCardinality(String),
    cat_id           LowCardinality(String),
    amount           Float64,
    name_1           String,
    name_2           String,
    gender           LowCardinality(String),
    us_state         LowCardinality(String),
    lat              Float64,
    lon              Float64,
    merchant_lat     Float64,
    merchant_lon     Float64,
    target           UInt8
)
ENGINE = MergeTree
ORDER BY (us_state, transaction_time);

CREATE MATERIALIZED VIEW IF NOT EXISTS transactions_db.transactions_mv
TO transactions_db.transactions
AS SELECT
    transaction_time,
    merch,
    cat_id,
    amount,
    name_1,
    name_2,
    gender,
    us_state,
    lat,
    lon,
    merchant_lat,
    merchant_lon,
    target
FROM transactions_db.transaction_queue;