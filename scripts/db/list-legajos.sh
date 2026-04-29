#!/usr/bin/env bash
# =============================================================================
# list-legajos.sh - List legajos across all tenants ordered by created_at
# =============================================================================
# Read-only query against the legajos table in every tenant_* schema of the
# rayuela database. Results are merged via UNION ALL and ordered globally by
# created_at (DESC by default — newest first).
#
# Usage:
#   ./scripts/db/list-legajos.sh [OPTIONS]
#
# Options:
#   --namespace <ns>, -n <ns>   Override namespace (default: rayuela-prod)
#   --asc                       Sort oldest first (default: newest first)
#   --verbose, -v               Add id, dni, fecha_alta, activo columns
#   -h, --help                  Show this help message
# =============================================================================

set -e

# ─────────────────────────────────────────────────────────────────
# Defaults
# ─────────────────────────────────────────────────────────────────
NS="rayuela-prod"
DB="rayuela"
USER="grex"
SORT_DIR="DESC"
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
  echo "  --asc                       Sort oldest first (default: newest first)"
  echo "  --verbose, -v               Add id, dni, fecha_alta, activo columns"
  echo "  -h, --help                  Show this help message"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace|-n) NS="$2"; shift 2 ;;
    --asc)          SORT_DIR="ASC"; shift ;;
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
# Display header
# ─────────────────────────────────────────────────────────────────
SORT_LABEL="newest first (created_at DESC)"
if [[ "$SORT_DIR" == "ASC" ]]; then
  SORT_LABEL="oldest first (created_at ASC)"
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  Legajos (todos los tenants)${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo -e "  Namespace:  ${CYAN}${NS}${NC}"
echo -e "  Database:   ${CYAN}${DB}${NC}"
echo -e "  Pod:        ${CYAN}${POD}${NC}"
echo -e "  Orden:      ${CYAN}${SORT_LABEL}${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────
# Discover tenant schemas
# ─────────────────────────────────────────────────────────────────
SCHEMAS=$(kubectl exec -i "${POD}" -n "${NS}" -- psql -U "${USER}" -d "${DB}" \
  --no-align --tuples-only -c \
  "SELECT schema_name FROM information_schema.schemata
    WHERE schema_name LIKE 'tenant_%' ORDER BY schema_name;" \
  | tr -d '\r')

if [[ -z "$SCHEMAS" ]]; then
  echo -e "${YELLOW}No tenant_* schemas found. Nothing to list.${NC}"
  echo ""
  exit 0
fi

SCHEMA_COUNT=$(echo "$SCHEMAS" | wc -l | tr -d ' ')
echo -e "  Tenants:    ${CYAN}${SCHEMA_COUNT}${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────
# Build UNION ALL query across every tenant schema
# ─────────────────────────────────────────────────────────────────
UNION_SQL=""
while IFS= read -r SCHEMA; do
  [[ -z "$SCHEMA" ]] && continue
  TENANT_UUID="${SCHEMA#tenant_}"
  if [[ -n "$UNION_SQL" ]]; then
    UNION_SQL+=$'\n        UNION ALL\n'
  fi
  UNION_SQL+="        SELECT '${TENANT_UUID}'::text AS tenant,
               l.created_at,
               bu.code  AS bu_code,
               bu.name  AS bu_name,
               l.cuil,
               l.apellido,
               l.nombre,
               l.id,
               l.dni,
               l.fecha_alta,
               l.activo
          FROM \"${SCHEMA}\".legajos l
          JOIN \"${SCHEMA}\".business_units bu ON bu.id = l.business_unit_id"
done <<< "$SCHEMAS"

if [[ "$VERBOSE" == true ]]; then
  SELECT_COLS=$(cat <<'EOF'
    created_at      AS "Creado",
    tenant          AS "Tenant",
    bu_code         AS "BU",
    cuil            AS "CUIL",
    apellido        AS "Apellido",
    nombre          AS "Nombre",
    id              AS "ID",
    dni             AS "DNI",
    fecha_alta      AS "Alta",
    activo          AS "Activo"
EOF
)
else
  SELECT_COLS=$(cat <<'EOF'
    created_at      AS "Creado",
    tenant          AS "Tenant",
    bu_code         AS "BU",
    cuil            AS "CUIL",
    apellido        AS "Apellido",
    nombre          AS "Nombre"
EOF
)
fi

# ─────────────────────────────────────────────────────────────────
# Run main query
# ─────────────────────────────────────────────────────────────────
echo -e "${BOLD}── Resultados ──────────────────────────${NC}"
echo ""

kubectl exec -i "${POD}" -n "${NS}" -- psql -U "${USER}" -d "${DB}" <<EOSQL
\\pset footer off
SELECT
${SELECT_COLS}
FROM (
${UNION_SQL}
) t
ORDER BY created_at ${SORT_DIR};
EOSQL

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}── Resumen ─────────────────────────────${NC}"
echo ""

# Per-tenant breakdown
echo -e "${BOLD}  Por tenant:${NC}"
kubectl exec -i "${POD}" -n "${NS}" -- psql -U "${USER}" -d "${DB}" <<EOSQL
\\pset footer off
SELECT
    tenant                                    AS "Tenant",
    COUNT(*)                                  AS "Total",
    COUNT(*) FILTER (WHERE activo)            AS "Activos",
    COUNT(*) FILTER (WHERE NOT activo)        AS "Inactivos"
FROM (
${UNION_SQL}
) t
GROUP BY tenant
ORDER BY tenant;
EOSQL

# Global totals
COUNTS=$(kubectl exec -i "${POD}" -n "${NS}" -- psql -U "${USER}" -d "${DB}" \
  --no-align --tuples-only --field-separator=' ' <<EOSQL
SELECT
    COUNT(*)                              AS total,
    COUNT(*) FILTER (WHERE activo)        AS active,
    COUNT(*) FILTER (WHERE NOT activo)    AS inactive
FROM (
${UNION_SQL}
) t;
EOSQL
)

TOTAL=$(echo "$COUNTS" | awk '{print $1}')
ACTIVE=$(echo "$COUNTS" | awk '{print $2}')
INACTIVE=$(echo "$COUNTS" | awk '{print $3}')

echo ""
echo -e "${BOLD}  Totales globales:${NC}"
echo -e "    Total:      ${GREEN}${TOTAL}${NC}"
echo -e "    Activos:    ${GREEN}${ACTIVE}${NC}"
echo -e "    Inactivos:  ${YELLOW}${INACTIVE}${NC}"
echo ""
