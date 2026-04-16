# Nordhem Platform — Superset configuration

import os

SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "nordhem_superset_secret")

# Use PostgreSQL as Superset's metadata database
SQLALCHEMY_DATABASE_URI = (
    f"postgresql+psycopg2://"
    f"{os.environ.get('POSTGRES_USER', 'nordhem')}:"
    f"{os.environ.get('POSTGRES_PASSWORD', 'nordhem_secret')}@"
    f"postgres:5432/superset_metadata"
)

# Feature flags
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
}

# Allow Trino connection
PREVENT_UNSAFE_DB_CONNECTIONS = False
