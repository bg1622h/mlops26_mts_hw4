#!/usr/bin/env python3
"""read csv and send transactions to kafka."""
import argparse
import csv
import json
import math
from datetime import datetime
from uuid import uuid4
from kafka import KafkaProducer
from tqdm import tqdm

def get_value(row, key, default=""):
    value = row.get(key)
    if value is not None and value.strip():
        return value.strip()
    else:
        return default


def parse_datetime(value):
    return datetime.strptime(value, "%Y-%m-%d %H:%M").strftime("%Y-%m-%d %H:%M:%S")

def make_message(row, schema="base"):
    transaction_time = parse_datetime(get_value(row, "transaction_time"))
    amount = float(get_value(row, "amount"))
    label = get_value(row, "target")
    if schema == "dbt" and label == "":
        raise ValueError("Target is required for the dbt schema")
    target = int(label)
    category = get_value(row, "cat_id")
    state = get_value(row, "us_state")
    message = {
        "transaction_id": str(uuid4()),
        "transaction_time": transaction_time,
    }
    if schema == "base":
        message.update(category=category, state=state, amount=amount, is_fraud=target)
        return message
    if schema != "dbt":
        raise ValueError(f"Unknown schema: {schema}")
    first_name = get_value(row, "name_1")
    last_name = get_value(row, "name_2")
    merchant = get_value(row, "merch")
    message.update({
        "merch": merchant,
        "cat_id": category,
        "amount": amount,
        "name_1": first_name,
        "name_2": last_name,
        "gender": get_value(row, "gender", default="U"),
        "us_state": state,
        "lat": float(get_value(row, "lat")),
        "lon": float(get_value(row, "lon")),
        "merchant_lat": float(get_value(row, "merchant_lat")),
        "merchant_lon": float(get_value(row, "merchant_lon")),
        "target": target,
    })
    return message

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", default="data/transactions.csv")
    parser.add_argument("--bootstrap-servers", default="localhost:9095")
    parser.add_argument("--schema", choices=["base", "dbt"], default="base")
    parser.add_argument("--topic")
    args = parser.parse_args()
    topic = args.topic or ("transactions_dbt" if args.schema == "dbt" else "transactions")
    if (args.schema == "base" and topic == "transactions_dbt") or (
        args.schema == "dbt" and topic == "transactions"
    ):
        parser.error("Topic does not match --schema")

    print("Initialize kafka producer")
    producer = KafkaProducer(
        bootstrap_servers=args.bootstrap_servers,
        value_serializer=lambda row: json.dumps(row, allow_nan=False).encode("utf-8"),
        acks="all",
    )
    print("Initialization done")
    count = 0
    pending = []
    try:
        with open(args.csv, newline="", encoding="utf-8") as file:
            total_rows = max(0, sum(1 for _ in file) - 1)

        with open(args.csv, newline="", encoding="utf-8") as file:
            reader = csv.DictReader(file)
            for row in tqdm(reader, total=total_rows, desc="Loading data in kafka topic"):
                try:
                    message = make_message(row, args.schema)
                except ValueError as error:
                    raise ValueError(f"CSV line {reader.line_num}: {error}") from error
                pending.append(producer.send(topic, message))
                count += 1
                if len(pending) >= 1000:
                    for future in pending:
                        future.get(timeout=60)
                    pending.clear()
        print("Sending data...")
        producer.flush(timeout=60)
        for future in pending:
            future.get(timeout=60)
        print("Done")
    finally:
        producer.close(timeout=60)
    print(f"Sent {count} rows to Kafka topic '{topic}'")


if __name__ == "__main__":
    main()