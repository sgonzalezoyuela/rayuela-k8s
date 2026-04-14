#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# bump-version.sh — Update Rayuela version across env configs
# ──────────────────────────────────────────────────────────────
#
# Usage:
#   ./scripts/release/bump-version.sh <version> <env>
#
# Arguments:
#   version   Semver-like version string (e.g. 0.6.0, 1.0.0-rc1, 0.6.0-dev)
#   env       Target environment: dev, prod, or all
#
# Examples:
#   ./scripts/release/bump-version.sh 0.6.0 dev
#   ./scripts/release/bump-version.sh 1.0.0-rc1 prod
#   ./scripts/release/bump-version.sh 0.7.0 all
#
# What it does:
#   1. Updates RAYUELA_VERSION in env/<env>/patches/configmap.yaml
#   2. Updates newTag in env/<env>/kustomization.yaml
#   3. Shows a summary of changes with next steps
# ──────────────────────────────────────────────────────────────

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# ── Functions ─────────────────────────────────────────────────

usage() {
    echo -e "${BOLD}Usage:${NC} $0 <version> <env>"
    echo ""
    echo "  version   Semver-like version string (e.g. 0.6.0, 1.0.0-rc1, 0.6.0-dev)"
    echo "  env       Target environment: dev, prod, or all"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  $0 0.6.0 dev"
    echo "  $0 1.0.0-rc1 prod"
    echo "  $0 0.7.0 all"
    exit 1
}

bump_env() {
    local env="$1"
    local version="$2"

    local configmap_file="${REPO_ROOT}/env/${env}/patches/configmap.yaml"
    local kustomization_file="${REPO_ROOT}/env/${env}/kustomization.yaml"

    local padding
    padding=$(printf '─%.0s' $(seq 1 $((55 - ${#env}))))
    echo -e "\n${BOLD}── ${env} ${padding}${NC}\n"

    # ── Validate files exist ──────────────────────────────────
    if [[ ! -f "$configmap_file" ]]; then
        echo -e "  ${RED}ERROR:${NC} File not found: env/${env}/patches/configmap.yaml"
        exit 1
    fi

    if [[ ! -f "$kustomization_file" ]]; then
        echo -e "  ${RED}ERROR:${NC} File not found: env/${env}/kustomization.yaml"
        exit 1
    fi

    # ── Update configmap ──────────────────────────────────────
    sed -i "s/RAYUELA_VERSION: \".*\"/RAYUELA_VERSION: \"${version}\"/" "$configmap_file"

    local configmap_result
    configmap_result=$(grep 'RAYUELA_VERSION:' "$configmap_file" | xargs)

    echo -e "  ${CYAN}env/${env}/patches/configmap.yaml${NC}"
    echo -e "    ${configmap_result}  ${GREEN}\u2713${NC}"

    # ── Update kustomization ──────────────────────────────────
    sed -i "s/newTag: \".*\"/newTag: \"${version}\"/" "$kustomization_file"

    local kustomization_result
    kustomization_result=$(grep 'newTag:' "$kustomization_file" | xargs)

    echo -e "\n  ${CYAN}env/${env}/kustomization.yaml${NC}"
    echo -e "    ${kustomization_result}  ${GREEN}\u2713${NC}"
}

# ── Validate arguments ────────────────────────────────────────

if [[ $# -lt 2 ]]; then
    echo -e "${RED}ERROR:${NC} Missing required arguments.\n"
    usage
fi

VERSION="$1"
ENV="$2"

if [[ -z "$VERSION" ]]; then
    echo -e "${RED}ERROR:${NC} Version cannot be empty.\n"
    usage
fi

if [[ "$ENV" != "dev" && "$ENV" != "prod" && "$ENV" != "all" ]]; then
    echo -e "${RED}ERROR:${NC} Invalid environment '${ENV}'. Must be dev, prod, or all.\n"
    usage
fi

# ── Header ────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}$(printf '\u2550%.0s' $(seq 1 60))${NC}"
echo -e "${BOLD}  Rayuela Version Bump${NC}"
echo -e "${BOLD}$(printf '\u2550%.0s' $(seq 1 60))${NC}"
echo ""
echo -e "  ${BOLD}Version:${NC} ${GREEN}${VERSION}${NC}"
echo -e "  ${BOLD}Target:${NC}  ${YELLOW}${ENV}${NC}"

# ── Apply changes ─────────────────────────────────────────────

if [[ "$ENV" == "all" ]]; then
    bump_env "dev" "$VERSION"
    bump_env "prod" "$VERSION"
else
    bump_env "$ENV" "$VERSION"
fi

# ── Footer ────────────────────────────────────────────────────

echo ""
echo -e "\n${BOLD}$(printf '\u2550%.0s' $(seq 1 60))${NC}"
echo -e "${BOLD}  Done! Version updated to ${GREEN}${VERSION}${BOLD} for ${YELLOW}${ENV}${NC}"
echo -e "${BOLD}$(printf '\u2550%.0s' $(seq 1 60))${NC}"

# ── Next steps ────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Next steps:${NC}"

if [[ "$ENV" == "all" ]]; then
    echo -e "  1. Review changes:  ${CYAN}git diff env/${NC}"
    echo -e "  2. Commit:          ${CYAN}git add env/ && git commit -m 'release: bump all to ${VERSION}'${NC}"
    echo -e "  3. Deploy dev:      ${CYAN}kubectl apply -k env/dev${NC}"
    echo -e "  4. Deploy prod:     ${CYAN}kubectl apply -k env/prod${NC}"
else
    echo -e "  1. Review changes:  ${CYAN}git diff env/${ENV}/${NC}"
    echo -e "  2. Commit:          ${CYAN}git add env/${ENV}/ && git commit -m 'release: bump ${ENV} to ${VERSION}'${NC}"
    echo -e "  3. Deploy:          ${CYAN}kubectl apply -k env/${ENV}${NC}"
fi

echo ""
