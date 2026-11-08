.PHONY: deps debug seed run test build docs all clean lint fix

deps:
	dbt deps --profiles-dir .

debug:
	dbt debug --profiles-dir .

seed:
	dbt seed --profiles-dir .

run:
	dbt run --profiles-dir .

test:
	dbt test --profiles-dir .

build:
	dbt build --profiles-dir .

docs:
	dbt docs generate --profiles-dir .
	dbt docs serve --profiles-dir . --port 8081

all: deps seed
	dbt build --profiles-dir .

lint:
	cd .. && sqlfluff lint dbt/models dbt/macros dbt/tests

fix:
	cd .. && sqlfluff fix dbt/models dbt/macros dbt/tests

clean:
	dbt clean --profiles-dir .