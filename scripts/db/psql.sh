#!/usr/bin/env bash
# =============================================================================
# psql.sh - Open a psql shell on a K8s rayuela database pod
# =============================================================================
# Connects to the rayuela-db-0 pod in the chosen environment's namespace and
# launches an interactive psql session via `kubectl exec`.
#
# Usage:
#   ./scripts/db/psql.sh <env> [dbname]
#
# Arguments:
#   env     'dev' or 'prod'
#   dbname  database name (default: rayuela)
#
# Environment overrides:
#   DB_USER  Database username (default: grex)
#
# Examples:
#   ./scripts/db/psql.sh dev
#   ./scripts/db/psql.sh prod
#   ./scripts/db/psql.sh prod some_other_db
# =============================================================================

set -euo pipefail

# ── Help ────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $0 <env> [dbname]

Arguments:
  env     'dev' or 'prod'
  dbname  database name (default: rayuela)

Examples:
  $0 dev
  $0 prod
EOF
  exit "${1:-1}"
}

case "${1:-}" in
  -h|--help) usage 0 ;;
  "")        usage   ;;
esac

ENV_NAME="$1"
DB_NAME="${2:-rayuela}"

case "$ENV_NAME" in
  dev)
    NAMESPACE="rayuela-dev"
    ;;
  prod)
    NAMESPACE="rayuela-prod"
    ;;
  *)
    echo "ERROR: env must be 'dev' or 'prod' (got '$ENV_NAME')" >&2
    echo "" >&2
    usage
    ;;
esac

DB_USER="${DB_USER:-grex}"

exec kubectl exec -it -n "$NAMESPACE" rayuela-db-0 -- psql -U "$DB_USER" -d "$DB_NAME"
