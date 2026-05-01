#!/usr/bin/env bash
# =============================================================================
# ha.sh - Connect to a K8s rayuela database using harlequin
# =============================================================================
# Sets up a kubectl port-forward to the rayuela-db StatefulSet in the chosen
# environment, then launches the harlequin TUI against it. The port-forward
# is automatically torn down when harlequin exits.
#
# Credentials:
#   The DB password is read from the environment variable DB_PASSWORD, which
#   is exported by scripts/db/env-{prod,dev}.sh — typically by calling
#   `pass show wk/grex/rayuela/{prod,dev}/db`.
#
# Usage:
#   ./scripts/db/ha.sh <env> [dbname]
#
# Arguments:
#   env     'dev' or 'prod'
#   dbname  database name (default: rayuela)
#
# Environment overrides:
#   LOCAL_PORT  Local port for the port-forward
#               (default: 15433 for dev, 15434 for prod)
#   DB_USER     Database username (default: grex)
#
# Examples:
#   ./scripts/db/ha.sh dev
#   ./scripts/db/ha.sh prod
#   LOCAL_PORT=15999 ./scripts/db/ha.sh dev
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  LOCAL_PORT=15999 $0 dev
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
    DEFAULT_LOCAL_PORT="15433"
    ;;
  prod)
    NAMESPACE="rayuela-prod"
    DEFAULT_LOCAL_PORT="15434"
    ;;
  *)
    echo "ERROR: env must be 'dev' or 'prod' (got '$ENV_NAME')" >&2
    echo "" >&2
    usage
    ;;
esac

# ── Source the per-env credentials file ─────────────────────────────────────
ENV_FILE="${SCRIPT_DIR}/env-${ENV_NAME}.sh"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: env file not found: $ENV_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "${DB_PASSWORD:-}" ]]; then
  echo "ERROR: DB_PASSWORD not set after sourcing $ENV_FILE" >&2
  echo "       Make sure 'pass' is installed and the entry exists" >&2
  echo "       (try: pass show wk/grex/rayuela/${ENV_NAME}/db)" >&2
  exit 1
fi

DB_USER="${DB_USER:-grex}"
SVC="rayuela-db"
LOCAL_PORT="${LOCAL_PORT:-$DEFAULT_LOCAL_PORT}"
REMOTE_PORT="5432"

# ── Prerequisites ───────────────────────────────────────────────────────────
for cmd in kubectl harlequin; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: '$cmd' is not installed" >&2
    echo "       Run inside the project's nix shell:  nix develop" >&2
    exit 1
  fi
done

if ! kubectl get -n "$NAMESPACE" "svc/$SVC" >/dev/null 2>&1; then
  echo "ERROR: service ${NAMESPACE}/${SVC} not found" >&2
  echo "       Check you're connected to the right cluster:" >&2
  echo "         kubectl config current-context" >&2
  exit 1
fi

# ── Port-forward in background, with cleanup ────────────────────────────────
echo "▶ port-forward ${NAMESPACE}/${SVC} → localhost:${LOCAL_PORT}"
kubectl port-forward -n "$NAMESPACE" "svc/${SVC}" "${LOCAL_PORT}:${REMOTE_PORT}" \
  >/dev/null 2>&1 &
PF_PID=$!

cleanup() {
  if kill -0 "$PF_PID" 2>/dev/null; then
    kill "$PF_PID" 2>/dev/null || true
    wait "$PF_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# Give kubectl port-forward a moment to bind the local port. ~5s ought to
# be enough; harlequin will surface a clear error if not.
sleep 2

if ! kill -0 "$PF_PID" 2>/dev/null; then
  echo "ERROR: kubectl port-forward exited unexpectedly" >&2
  echo "       Re-run with kubectl port-forward in a separate shell to debug:" >&2
  echo "         kubectl port-forward -n ${NAMESPACE} svc/${SVC} ${LOCAL_PORT}:${REMOTE_PORT}" >&2
  exit 1
fi

# ── Launch harlequin ────────────────────────────────────────────────────────
echo "▶ harlequin → ${ENV_NAME}/${DB_NAME} (user: ${DB_USER})"
harlequin -a postgres \
  "postgresql://${DB_USER}:${DB_PASSWORD}@127.0.0.1:${LOCAL_PORT}/${DB_NAME}"
