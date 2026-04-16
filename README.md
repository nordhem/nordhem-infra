# nordhem-infra

Infrastructure for the Nordhem Data Platform. Runs all services locally via Docker Compose.

## Services

| Service | Image | Port | Purpose |
|---|---|---|---|
| PostgreSQL 16 | `postgres:16` | 5432 | OLTP source (`nordhem_source`) + Dagster metadata (`dagster_state`) + Superset metadata (`superset_metadata`) |
| MinIO | `minio/minio:latest` | 9000 / 9001 | Local S3-compatible data lake (`nordhem-lake` bucket) |
| Trino | `trinodb/trino:latest` | 8080 | Query engine over Iceberg on MinIO |
| Apache Superset | custom build | 8088 | Dashboards and reporting |

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

| Service | URL | Default Credentials |
|---|---|---|
| MinIO Console | http://localhost:9001 | See `.env` |
| Trino UI | http://localhost:8080 | None required |
| Superset | http://localhost:8088 | See `.env` |

## Postgres Databases

| Database | Purpose |
|---|---|
| `nordhem_source` | OLTP source system — `reference` and `operational` schemas |
| `dagster_state` | Dagster pipeline metadata |
| `superset_metadata` | Superset internal metadata |

## Connecting to Postgres

```bash
docker exec -it nordhem_postgres psql -U nordhem -d postgres
```

Once inside, run these to verify the setup:

```sql
-- List all databases (expect: postgres, dagster_state, nordhem_source, superset_metadata)
\l

-- Connect to nordhem_source
\c nordhem_source

-- List schemas (expect: reference, operational, public)
\dn

-- List reference tables (expect: diagnoses, plan_types, procedure_codes, providers)
\dt reference.*

-- List operational tables (expect: 11 tables)
\dt operational.*

-- Exit
\q
```

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

## Notes

- Superset is built from a custom Dockerfile (`superset/Dockerfile`) to include `psycopg2-binary`
- MinIO bucket `nordhem-lake` is created automatically on first startup via `minio_init`
- All operational tables have `tenant_id`, UUID PKs, audit columns, soft deletes, and RLS enabled
- Tables are created but unpopulated — data is loaded via `nordhem-pipelines`

## Part of the Nordhem Platform

| Repo | Purpose |
|---|---|
| [nordhem-infra](https://github.com/nordhem/nordhem-infra) | This repo |
| [nordhem-pipelines](https://github.com/nordhem/nordhem-pipelines) | Dagster pipelines |
| [nordhem-transforms](https://github.com/nordhem/nordhem-transforms) | dbt models |
| [nordhem-dashboards](https://github.com/nordhem/nordhem-dashboards) | Superset dashboards |
| [nordhem-docs](https://github.com/nordhem/nordhem-docs) | Architecture docs |
