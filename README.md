# nordhem-infra

Infrastructure for the Nordhem Data Platform. Runs all services locally via Docker Compose.

## Services

| Service | Port | Purpose |
|---|---|---|
| PostgreSQL 16 | 5432 | OLTP source (`nordhem_source`) + Dagster metadata (`dagster_state`) |
| MinIO | 9000 / 9001 | Local S3-compatible data lake (`nordhem-lake`) |
| Trino | 8080 | Query engine over Iceberg on MinIO |
| Apache Superset | 8088 | Dashboards |

## Quick Start

```bash
# 1. Copy environment variables
cp .env.example .env

# 2. Fill in your values in .env

# 3. Start all services
docker-compose up -d

# 4. Verify all services are running
docker-compose ps
```

## Service URLs

| Service | URL |
|---|---|
| MinIO Console | http://localhost:9001 |
| Trino UI | http://localhost:8080 |
| Superset | http://localhost:8088 |

## Data Persistence

All data persists via Docker named volumes:
- `postgres_data` — PostgreSQL databases
- `minio_data` — Data lake files

Stop services without losing data:
```bash
docker-compose stop
```

Destroy everything including data:
```bash
docker-compose down -v
```

## Part of the Nordhem Platform

| Repo | Purpose |
|---|---|
| [nordhem-infra](https://github.com/nordhem/nordhem-infra) | This repo |
| [nordhem-pipelines](https://github.com/nordhem/nordhem-pipelines) | Dagster pipelines |
| [nordhem-transforms](https://github.com/nordhem/nordhem-transforms) | dbt models |
| [nordhem-dashboards](https://github.com/nordhem/nordhem-dashboards) | Superset dashboards |
| [nordhem-docs](https://github.com/nordhem/nordhem-docs) | Architecture docs |
