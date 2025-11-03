#!/usr/bin/env bash
# Non-interactive startup helper for local dev PostgreSQL using custom port and DB name.

set -euo pipefail

# Read from env or use defaults
PGUSER="${PGUSER:-postgres}"
PGPASSWORD="${PGPASSWORD:-postgres}"
PGHOST="${PGHOST:-localhost}"
PGPORT="${PGPORT:-5000}"
DB_NAME="${DB_NAME:-ai_blog_generator_db}"

export PGPASSWORD

echo "Starting PostgreSQL dev instance expectations:"
echo "  Host: ${PGHOST}"
echo "  Port: ${PGPORT}"
echo "  User: ${PGUSER}"
echo "  DB:   ${DB_NAME}"

# The actual start of the Postgres service is environment-specific and omitted here.
# Ensure your local Postgres is running and listening on ${PGPORT}.
# This script focuses on idempotent DB creation for local setups.

# Attempt to create database if not exists
psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -tc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1 || \
  psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -c "CREATE DATABASE ${DB_NAME};"

echo "Database '${DB_NAME}' is ready on port ${PGPORT}."
