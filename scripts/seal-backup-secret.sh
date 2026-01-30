#!/usr/bin/env bash
# seal-backup-secret.sh - Seal backup secrets for Rayuela production
#
# Usage:
#   ./scripts/seal-backup-secret.sh
#
# This script seals the backup secrets for production:
#   - restic-password: Restic repository encryption password
#
# Backup is only configured for prod environment.
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

# Backup is only for prod
NAMESPACE="rayuela"
OUTPUT_FILE="${REPO_ROOT}/env/prod/sealed-secrets/backup-secrets.yaml"

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
echo -e "${CYAN}  Sealing backup secrets for production${NC}"
echo -e "${CYAN}  Namespace: ${NAMESPACE}${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Prompt for restic password
echo -e "${YELLOW}Restic repository password (required):${NC}"
echo "  This password encrypts your backups in the restic repository."
echo "  Use the same password you used to initialize the restic repo."
echo ""
read -s -p "  Enter restic password: " RESTIC_PASSWORD
echo ""

if [[ -z "$RESTIC_PASSWORD" ]]; then
    echo -e "${RED}Error: Restic password is required${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Sealing backup secret...${NC}"

# Create the sealed secret
kubectl create secret generic rayuela-backup-secrets \
    --namespace="${NAMESPACE}" \
    --from-literal=restic-password="${RESTIC_PASSWORD}" \
    --dry-run=client \
    -o yaml | \
kubeseal \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    --format=yaml > "${OUTPUT_FILE}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Successfully sealed backup secret!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "The sealed secret has been written to:"
echo "  ${OUTPUT_FILE}"
echo ""
echo "Namespace: ${NAMESPACE}"
echo ""
echo "Secret contents:"
echo "  - restic-password: ********"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Review the sealed secret: cat ${OUTPUT_FILE}"
echo "  2. Commit to git: git add ${OUTPUT_FILE} && git commit -m 'chore: update backup secrets'"
echo "  3. Deploy: kubectl apply -k env/prod"
echo ""
