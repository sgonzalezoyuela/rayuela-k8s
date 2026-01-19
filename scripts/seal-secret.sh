#!/usr/bin/env bash
# seal-secret.sh - Seal secrets for Rayuela environments
#
# Usage:
#   ./scripts/seal-secret.sh <environment>
#
# The script will prompt for the required values interactively.
#
# Examples:
#   ./scripts/seal-secret.sh dev
#   ./scripts/seal-secret.sh prod
#
# Prerequisites:
#   - kubeseal CLI installed
#   - kubectl configured to target cluster
#   - Sealed Secrets controller installed in cluster

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
    echo "Usage: $0 <environment>"
    echo ""
    echo "Arguments:"
    echo "  environment   Environment to seal secrets for (dev or prod)"
    echo ""
    echo "The script will prompt for:"
    echo "  - Database password (required)"
    echo "  - OIDC client ID (optional)"
    echo "  - OIDC client secret (optional)"
    echo ""
    echo "Examples:"
    echo "  $0 dev"
    echo "  $0 prod"
    exit 1
}

# Check arguments
if [[ $# -lt 1 ]]; then
    usage
fi

ENV="$1"

# Validate environment
if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
    echo -e "${RED}Error: Environment must be 'dev' or 'prod'${NC}"
    usage
fi

# Check for kubeseal
if ! command -v kubeseal &>/dev/null; then
    echo -e "${RED}Error: kubeseal is not installed${NC}"
    echo ""
    echo "Install kubeseal:"
    echo "  brew install kubeseal           # macOS"
    echo "  nix-env -iA nixpkgs.kubeseal    # Nix"
    echo "  # Or download from: https://github.com/bitnami-labs/sealed-secrets/releases"
    exit 1
fi

# Check for kubectl
if ! command -v kubectl &>/dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check cluster connectivity
echo -e "${YELLOW}Checking cluster connectivity...${NC}"
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo "Make sure kubectl is configured correctly"
    exit 1
fi

# Check if sealed-secrets controller is installed
echo -e "${YELLOW}Checking Sealed Secrets controller...${NC}"
if ! kubectl get deployment -n kube-system sealed-secrets-controller &>/dev/null; then
    echo -e "${RED}Error: Sealed Secrets controller not found${NC}"
    echo ""
    echo "Install it first:"
    echo "  kubectl apply -k infra/sealed-secrets"
    exit 1
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Sealing secrets for: ${ENV}${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Prompt for database password
echo -e "${YELLOW}Database password (required):${NC}"
read -s -p "  Enter password: " DB_PASSWORD
echo ""

if [[ -z "$DB_PASSWORD" ]]; then
    echo -e "${RED}Error: Database password is required${NC}"
    exit 1
fi

# Prompt for OIDC credentials (optional)
echo ""
echo -e "${YELLOW}OAuth2/OIDC credentials (press Enter to skip):${NC}"
read -p "  OIDC Client ID: " OIDC_CLIENT_ID
read -s -p "  OIDC Client Secret: " OIDC_CLIENT_SECRET
echo ""

# Output file path
OUTPUT_FILE="${REPO_ROOT}/env/${ENV}/sealed-secrets/secrets.yaml"

echo ""
echo -e "${YELLOW}Sealing secrets...${NC}"

# Build the secret creation command
SECRET_ARGS=(
    "--namespace=rayuela"
    "--from-literal=db-password=${DB_PASSWORD}"
)

if [[ -n "$OIDC_CLIENT_ID" ]]; then
    SECRET_ARGS+=("--from-literal=oidc-client-id=${OIDC_CLIENT_ID}")
else
    # Use placeholder for optional secrets
    SECRET_ARGS+=("--from-literal=oidc-client-id=not-configured")
fi

if [[ -n "$OIDC_CLIENT_SECRET" ]]; then
    SECRET_ARGS+=("--from-literal=oidc-client-secret=${OIDC_CLIENT_SECRET}")
else
    SECRET_ARGS+=("--from-literal=oidc-client-secret=not-configured")
fi

# Create the sealed secret
kubectl create secret generic rayuela-secrets \
    "${SECRET_ARGS[@]}" \
    --dry-run=client \
    -o yaml | \
kubeseal \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    --format=yaml > "${OUTPUT_FILE}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Successfully sealed secrets for ${ENV} environment!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "The sealed secret has been written to:"
echo "  ${OUTPUT_FILE}"
echo ""
echo "Secrets included:"
echo "  - db-password: ********"
if [[ -n "$OIDC_CLIENT_ID" ]]; then
    echo "  - oidc-client-id: ${OIDC_CLIENT_ID:0:8}..."
    echo "  - oidc-client-secret: ********"
else
    echo "  - oidc-client-id: (not configured)"
    echo "  - oidc-client-secret: (not configured)"
fi
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Review the sealed secret: cat ${OUTPUT_FILE}"
echo "  2. Commit to git: git add ${OUTPUT_FILE} && git commit -m 'chore: update ${ENV} secrets'"
echo "  3. Deploy: kubectl apply -k env/${ENV}"
echo ""
