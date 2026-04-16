#!/usr/bin/env bash
# =============================================================================
# list-modalidades-contratacion.sh - List modalidades de contratacion from DB
# =============================================================================
# Read-only query against the modalidades_contratacion catalog table in the
# rayuela database. By default shows only active rows (hasta IS NULL).
#
# Usage:
#   ./scripts/db/list-modalidades-contratacion.sh [OPTIONS]
#
# Options:
#   --namespace <ns>, -n <ns>   Override namespace (default: rayuela-prod)
#   --active                    Show only active rows — hasta IS NULL (default)
#   --all                       Include historical/expired rows too
#   --verbose, -v               Add id and version columns to the output
#   -h, --help                  Show this help message
# =============================================================================

set -e

# ─────────────────────────────────────────────────────────────────
# Defaults
# ─────────────────────────────────────────────────────────────────
NS="rayuela-prod"
DB="rayuela"
USER="grex"
FILTER="active"
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─────────────────────────────────────────────────────────────────
# Parse arguments
# ─────────────────────────────────────────────────────────────────
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --namespace <ns>, -n <ns>   Override namespace (default: rayuela-prod)"
  echo "  --active                    Show only active rows — hasta IS NULL (default)"
  echo "  --all                       Include historical/expired rows too"
  echo "  --verbose, -v               Add id and version columns to the output"
  echo "  -h, --help                  Show this help message"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace|-n) NS="$2"; shift 2 ;;
    --active)       FILTER="active"; shift ;;
    --all)          FILTER="all"; shift ;;
    --verbose|-v)   VERBOSE=true; shift ;;
    -h|--help)      usage ;;
    *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
  esac
done

# ─────────────────────────────────────────────────────────────────
# Prerequisites
# ─────────────────────────────────────────────────────────────────
if ! command -v kubectl &>/dev/null; then
  echo -e "${RED}Error: kubectl is not installed${NC}"
  exit 1
fi

if ! kubectl cluster-info &>/dev/null 2>&1; then
  echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
  exit 1
fi

# ─────────────────────────────────────────────────────────────────
# Pod detection
# ─────────────────────────────────────────────────────────────────
POD=$(kubectl get pods -n "${NS}" -l app=rayuela-db -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "rayuela-db-0")

# ─────────────────────────────────────────────────────────────────
# Build query
# ─────────────────────────────────────────────────────────────────
WHERE_CLAUSE=""
if [[ "$FILTER" == "active" ]]; then
  WHERE_CLAUSE="WHERE hasta IS NULL"
fi

if [[ "$VERBOSE" == true ]]; then
  SELECT_COLS=$(cat <<'EOF'
    id                           AS "ID",
    codigo                       AS "Código",
    desde                        AS "Desde",
    hasta                        AS "Hasta",
    descripcion                  AS "Descripción",
    aporte_obra_social           AS "OS Aporte",
    contribucion_obra_social     AS "OS Contrib.",
    version                      AS "Versión"
EOF
)
else
  SELECT_COLS=$(cat <<'EOF'
    codigo                       AS "Código",
    desde                        AS "Desde",
    hasta                        AS "Hasta",
    descripcion                  AS "Descripción",
    aporte_obra_social           AS "OS Aporte",
    contribucion_obra_social     AS "OS Contrib."
EOF
)
fi

FILTER_LABEL="active only (hasta IS NULL)"
if [[ "$FILTER" == "all" ]]; then
  FILTER_LABEL="all (including expired)"
fi

# ─────────────────────────────────────────────────────────────────
# Display header
# ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  Modalidades de Contratación${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo -e "  Namespace:  ${CYAN}${NS}${NC}"
echo -e "  Database:   ${CYAN}${DB}${NC}"
echo -e "  Pod:        ${CYAN}${POD}${NC}"
echo -e "  Filter:     ${CYAN}${FILTER_LABEL}${NC}"
echo ""
echo -e "${BOLD}── Resultados ──────────────────────────${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────
# Run main query
# ─────────────────────────────────────────────────────────────────
kubectl exec -i "${POD}" -n "${NS}" -- psql -U "${USER}" -d "${DB}" <<EOSQL
\\pset footer off
SELECT
${SELECT_COLS}
FROM modalidades_contratacion
${WHERE_CLAUSE}
ORDER BY codigo;
EOSQL

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}── Resumen ─────────────────────────────${NC}"

COUNTS=$(kubectl exec -i "${POD}" -n "${NS}" -- psql -U "${USER}" -d "${DB}" \
  --no-align --tuples-only --field-separator=' ' <<'EOSQL'
SELECT
    COUNT(*)                          AS total,
    COUNT(*) FILTER (WHERE hasta IS NULL) AS active
FROM modalidades_contratacion;
EOSQL
)

TOTAL=$(echo "$COUNTS" | awk '{print $1}')
ACTIVE=$(echo "$COUNTS" | awk '{print $2}')

echo ""
echo -e "  Total registros:  ${GREEN}${TOTAL}${NC}"
echo -e "  Activos:          ${GREEN}${ACTIVE}${NC}  ${YELLOW}(hasta IS NULL)${NC}"
echo ""
