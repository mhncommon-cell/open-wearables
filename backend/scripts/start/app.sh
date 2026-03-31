#!/bin/bash
set -x

# Init database
echo 'Applying migrations...'
if ! uv run alembic upgrade head; then
    echo 'ERROR: Migrations failed! Check DB connection settings.'
    echo "DB_HOST=$DB_HOST DB_PORT=$DB_PORT DB_NAME=$DB_NAME DB_USER=$DB_USER DB_SSL=$DB_SSL"
    exit 1
fi

# Initialize provider settings
echo 'Initializing provider settings...'
uv run python scripts/init_provider_settings.py || echo 'WARNING: init_provider_settings failed, continuing...'

# Initialize device priority table
echo 'Initializing priorities...'
uv run python scripts/init_device_priorities.py || echo 'WARNING: init_device_priorities failed, continuing...'

# Seed admin account (uses ADMIN_EMAIL/ADMIN_PASSWORD env vars, or defaults)
echo 'Seeding admin account...'
uv run python scripts/init/seed_admin.py || echo 'WARNING: seed_admin failed, continuing...'

# Initialize series type definitions
echo 'Initializing series type definitions...'
uv run python scripts/init/seed_series_types.py || echo 'WARNING: seed_series_types failed, continuing...'

# Initialize archival settings
echo 'Initializing archival settings...'
uv run python scripts/init/seed_archival_settings.py || echo 'WARNING: seed_archival_settings failed, continuing...'

# Use PORT env var if set (Railway injects this), otherwise default to 8000
APP_PORT="${PORT:-8000}"

# Init app
echo "Starting the FastAPI application on port $APP_PORT..."
if [ "$ENVIRONMENT" = "local" ]; then
    uv run fastapi dev app/main.py --host 0.0.0.0 --port "$APP_PORT"
else
    uv run fastapi run app/main.py --host 0.0.0.0 --port "$APP_PORT"
fi
