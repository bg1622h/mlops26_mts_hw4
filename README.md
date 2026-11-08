# MLOps homework 4: dbt

Код строит аналитические витрины по транзакциям и признаку мошенничества.
Данные загружаются из CSV через Kafka в ClickHouse, затем обрабатываются моделями dbt.

| Витрина | Метрики                                                                                  |
| --- |------------------------------------------------------------------------------------------|
| `mart_daily_state_metrics` | Количество, сумма, средний чек, P95 и доля крупных транзакций по дате/штату              |
| `mart_fraud_by_category` | Количество транзакций и мошеннических транзакций, fraud rate и суммы по категориям       |
| `mart_fraud_by_state` | Fraud rate, уникальные клиенты/продавцы и суммы по штатам                                |
| `mart_customer_risk_profile` | Активность клиента, первая/последняя транзакции, средний чек, fraud rate и уровень риска |
| `mart_hourly_fraud_pattern` | Показатели по дню недели и часу, флаг повышенного риска окна                             |
| `mart_merchant_analytics` | Оборот, fraud rate и флаг подозрительности продавца                                      |

После загрузки новых данных витрины обновляются командой `dbt build`.

## Подготовка

CSV файл положить в `data/train.csv`.

В `dbt/profiles.yml` должен быть профиль подключения. 

## Linux — Bash

```bash
# Окружение
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt -r dbt/requirements.txt

# Сборка
docker compose up -d --build
docker compose ps --all

# загрузка
docker compose exec -T clickhouse clickhouse-client --multiquery < sql/create_tables_dbt.sql
python scripts/read_data.py --csv data/train.csv --schema dbt

docker compose exec clickhouse clickhouse-client --query "SELECT count(), sum(target) FROM transactions_db.transactions"

# dbt
dbt deps --project-dir dbt --profiles-dir dbt
dbt debug --project-dir dbt --profiles-dir dbt
dbt build --project-dir dbt --profiles-dir dbt --no-partial-parse
```

## Windows — PowerShell

```powershell
# Окружение
if (!(Test-Path .\.venv\Scripts\python.exe)) {
    python -m venv .venv
}
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt -r dbt/requirements.txt

# Сборка
docker compose up -d --build
docker compose ps --all
# Дождаться healthy у Kafka и ClickHouse, Exited (0) у kafka-setup

# Загрузка
Get-Content .\sql\create_tables_dbt.sql -Raw | docker compose exec -T clickhouse clickhouse-client --multiquery
python .\scripts\read_data.py --csv .\data\train.csv --schema dbt

docker compose exec clickhouse clickhouse-client --query "SELECT count(), sum(target) FROM transactions_db.transactions"

# dbt
dbt deps --project-dir dbt --profiles-dir dbt
dbt debug --project-dir dbt --profiles-dir dbt
dbt build --project-dir dbt --profiles-dir dbt --no-partial-parse
```

Если CSV уже загружен, повторно запускать producer не нужно: повторная отправка добавит дубликаты.
Для обновления витрин достаточно `dbt build --project-dir dbt --profiles-dir dbt`.

Unit tests находятся в `dbt/models/staging/stg_transactions.yml`, в блоке `unit_tests`:
проверка границ сегментов суммы и проверка нормализации/дня недели.

## Документация для dbt

```bash
dbt docs generate --project-dir dbt --profiles-dir dbt
dbt docs serve --project-dir dbt --profiles-dir dbt --port 8081
```

Открыть http://localhost:8081, нажать `View Lineage Graph`.

Логи Linux:

```bash
mkdir -p docs
dbt --version > docs/dbt_version.log
dbt test --project-dir dbt --profiles-dir dbt --no-use-colors > docs/dbt_test.log 2>&1
cat docs/dbt_test.log
```

Логи PowerShell:

```powershell
New-Item -ItemType Directory -Force .\docs | Out-Null
dbt --version | Out-File -Encoding utf8 .\docs\dbt_version.log
dbt test --project-dir dbt --profiles-dir dbt --no-use-colors 2>&1 | Tee-Object -Variable dbtTestLog
$dbtTestLog | Out-File -Encoding utf8 .\docs\dbt_test.log
```