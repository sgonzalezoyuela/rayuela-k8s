#!/usr/bin/env bash
# seal-secret.sh - Seal database password for Rayuela environments
#
# Usage:
#   ./scripts/seal-secret.sh <environment> <password>
#
# Examples:
#   ./scripts/seal-secret.sh dev "my-dev-password"
#   ./scripts/seal-secret.sh prod "my-prod-password"
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
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
    echo "Usage: $0 <environment> <password>"
    echo ""
    echo "Arguments:"
    echo "  environment   Environment to seal secret for (dev or prod)"
    echo "  password      The database password to seal"
    echo ""
    echo "Examples:"
    echo "  $0 dev \"my-dev-password\""
    echo "  $0 prod \"my-prod-password\""
    exit 1
}

# Check arguments
if [[ $# -lt 2 ]]; then
    usage
fi

ENV="$1"
PASSWORD="$2"

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
    echo "  nix-env -i kubeseal             # Nix"
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

# Output file path
OUTPUT_FILE="${REPO_ROOT}/env/${ENV}/sealed-secrets/db-password.yaml"

echo -e "${YELLOW}Sealing secret for environment: ${ENV}${NC}"
echo -e "${YELLOW}Output file: ${OUTPUT_FILE}${NC}"

# Create the sealed secret
kubectl create secret generic rayuela-db \
    --namespace=rayuela \
    --from-literal=password="${PASSWORD}" \
    --dry-run=client \
    -o yaml |
    kubeseal \
        --controller-name=sealed-secrets-controller \
        --controller-namespace=kube-system \
        --format=yaml >"${OUTPUT_FILE}"

echo ""
echo -e "${GREEN}Successfully sealed secret for ${ENV} environment!${NC}"
echo ""
echo "The sealed secret has been written to:"
echo "  ${OUTPUT_FILE}"
echo ""
echo "You can now commit this file to git safely."
echo ""
echo "To deploy:"
echo "  kubectl apply -k env/${ENV}"
