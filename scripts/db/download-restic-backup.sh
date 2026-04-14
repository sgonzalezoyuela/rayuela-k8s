#!/usr/bin/env bash
# =============================================================================
# download-restic-backup.sh - Download a backup from the restic repository
# =============================================================================
# Connects to the restic REST server and restores a snapshot's .pgdump file
# into the local backups/restic/ directory.
#
# The restic repository is hosted on cemcc-t (accessed via Tailscale).
# You need the restic CLI installed and the repository password.
#
# Prerequisites:
#   - restic CLI installed (https://restic.readthedocs.io)
#   - Tailscale connected (to reach cemcc-t)
#   - Restic repository password (via RESTIC_PASSWORD env var or prompted)
#
# Usage:
#   ./scripts/db/download-restic-backup.sh                  # download latest
#   ./scripts/db/download-restic-backup.sh <snapshot-id>    # download specific
#   ./scripts/db/download-restic-backup.sh --list           # list snapshots
#
# Options:
#   --list              List available snapshots in the repository
#   --repo <url>        Override restic repository URL
#   -h, --help          Show this help message
#
# Environment:
#   RESTIC_REPOSITORY   Override default repository URL
#   RESTIC_PASSWORD     Restic repository password (prompted if not set)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DEFAULT_REPO="rest:http://cemcc-t:8000/rayuela"
BACKUP_DIR="${PROJECT_ROOT}/backups/restic"

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
  echo "Usage: $0 [<snapshot-id>] [OPTIONS]"
  echo "       $0 --list"
  echo ""
  echo "Arguments:"
  echo "  <snapshot-id>     Restic snapshot ID to restore (default: latest)"
  echo ""
  echo "Options:"
  echo "  --list            List available snapshots in the repository"
  echo "  --repo <url>      Override restic repository URL"
  echo "  -h, --help        Show this help message"
  echo ""
  echo "Environment:"
  echo "  RESTIC_REPOSITORY Override default repository URL"
  echo "  RESTIC_PASSWORD   Restic repository password (prompted if not set)"
  echo ""
  echo "Examples:"
  echo "  $0                                    # download latest snapshot"
  echo "  $0 abc123def                          # download specific snapshot"
  echo "  $0 --list                             # list all snapshots"
  echo "  $0 --repo rest:http://10.0.3.2:8000/rayuela   # use alternate repo"
  exit 0
}

SNAPSHOT_ID="latest"
LIST_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)        LIST_MODE=true; shift ;;
    --repo)        export RESTIC_REPOSITORY="$2"; shift 2 ;;
    -h|--help)     usage ;;
    -*)            echo -e "${RED}Unknown option: $1${NC}"; echo ""; usage ;;
    *)
      SNAPSHOT_ID="$1"; shift
      ;;
  esac
done

# Use default repo if not set via env or flag
export RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-$DEFAULT_REPO}"

# ─────────────────────────────────────────────────────────────────
# Prerequisites
# ─────────────────────────────────────────────────────────────────
if ! command -v restic &>/dev/null; then
  echo -e "${RED}Error: restic is not installed${NC}"
  echo ""
  echo "Install it from: https://restic.readthedocs.io/en/latest/020_installation.html"
  echo "  macOS:  brew install restic"
  echo "  Linux:  apt install restic / pacman -S restic"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo -e "${RED}Error: jq is not installed${NC}"
  echo ""
  echo "Install it:"
  echo "  macOS:  brew install jq"
  echo "  Linux:  apt install jq / pacman -S jq"
  exit 1
fi

# ─────────────────────────────────────────────────────────────────
# Password
# ─────────────────────────────────────────────────────────────────
if [[ -z "${RESTIC_PASSWORD:-}" ]]; then
  echo -n "Restic repository password: "
  read -rs RESTIC_PASSWORD
  echo ""
  export RESTIC_PASSWORD
fi

# ─────────────────────────────────────────────────────────────────
# Verify repository access
# ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}Connecting to restic repository...${NC}"
echo -e "  Repository: ${RESTIC_REPOSITORY}"
echo ""

if ! restic snapshots --json &>/dev/null; then
  echo -e "${RED}Error: Cannot access restic repository${NC}"
  echo ""
  echo "Check that:"
  echo "  1. Tailscale is connected (tailscale status)"
  echo "  2. The repository URL is correct"
  echo "  3. The password is correct"
  exit 1
fi

# ─────────────────────────────────────────────────────────────────
# List mode
# ─────────────────────────────────────────────────────────────────
if [[ "$LIST_MODE" == true ]]; then
  echo -e "${BOLD}=========================================="
  echo -e "Available Snapshots"
  echo -e "==========================================${NC}"
  echo ""
  restic snapshots --tag rayuela
  echo ""
  echo -e "Download a snapshot with:"
  echo -e "  $0 <snapshot-id>"
  echo -e "  $0                     ${CYAN}# latest${NC}"
  exit 0
fi

# ─────────────────────────────────────────────────────────────────
# Resolve snapshot metadata
# ─────────────────────────────────────────────────────────────────
echo -e "${CYAN}Resolving snapshot '${SNAPSHOT_ID}'...${NC}"

SNAPSHOT_JSON=$(restic snapshots --json --tag rayuela "${SNAPSHOT_ID}" 2>/dev/null || true)

if [[ -z "$SNAPSHOT_JSON" || "$SNAPSHOT_JSON" == "null" || "$SNAPSHOT_JSON" == "[]" ]]; then
  echo -e "${RED}Error: Snapshot '${SNAPSHOT_ID}' not found${NC}"
  echo ""
  echo "List available snapshots with: $0 --list"
  exit 1
fi

# When using "latest", restic returns all snapshots; pick the last one
if [[ "$SNAPSHOT_ID" == "latest" ]]; then
  SNAP_INFO=$(echo "$SNAPSHOT_JSON" | jq -r '.[-1]')
else
  SNAP_INFO=$(echo "$SNAPSHOT_JSON" | jq -r '.[0]')
fi

SNAP_SHORT_ID=$(echo "$SNAP_INFO" | jq -r '.short_id')
SNAP_TIME=$(echo "$SNAP_INFO" | jq -r '.time')
SNAP_DATE=$(echo "$SNAP_TIME" | cut -dT -f1)
SNAP_TAGS=$(echo "$SNAP_INFO" | jq -r '.tags | join(", ")')

# ─────────────────────────────────────────────────────────────────
# Download snapshot
# ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}=========================================="
echo -e "Downloading Restic Backup"
echo -e "==========================================${NC}"
echo ""
echo -e "  Snapshot:    ${SNAP_SHORT_ID}"
echo -e "  Date:        ${SNAP_TIME}"
echo -e "  Tags:        ${SNAP_TAGS}"
echo ""

mkdir -p "$BACKUP_DIR"

# Restore to a temp directory first
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo -e "${CYAN}Restoring snapshot...${NC}"

if [[ "$SNAPSHOT_ID" == "latest" ]]; then
  restic restore latest --target "$TEMP_DIR" --tag rayuela
else
  restic restore "$SNAPSHOT_ID" --target "$TEMP_DIR"
fi

# Find all .dump files in the restored snapshot
mapfile -t DUMP_FILES < <(find "$TEMP_DIR" -name "*.dump" -type f)

if [[ ${#DUMP_FILES[@]} -eq 0 ]]; then
  echo ""
  echo -e "${RED}Error: No .dump files found in snapshot${NC}"
  echo ""
  echo "Snapshot contents:"
  find "$TEMP_DIR" -type f | sed "s|${TEMP_DIR}/||"
  exit 1
fi

# Move each dump file to the output directory
echo ""
OUTPUT_FILES=()
for dump in "${DUMP_FILES[@]}"; do
  DB_NAME=$(basename "$dump" .dump)
  OUTPUT_FILENAME="restic-${SNAP_SHORT_ID}-${SNAP_DATE}-${DB_NAME}.pgdump"
  mv "$dump" "${BACKUP_DIR}/${OUTPUT_FILENAME}"
  FILE_SIZE=$(du -h "${BACKUP_DIR}/${OUTPUT_FILENAME}" | cut -f1)
  OUTPUT_FILES+=("${OUTPUT_FILENAME} (${FILE_SIZE})")
done

echo -e "${GREEN}=========================================="
echo -e "Download complete!"
echo -e "==========================================${NC}"
echo ""
for f in "${OUTPUT_FILES[@]}"; do
  echo -e "  ${GREEN}✓${NC} backups/restic/${f}"
done
echo ""
echo -e "Restore to local Docker:"
for f in "${OUTPUT_FILES[@]}"; do
  fname="${f%% *}"
  echo -e "  ./scripts/db/restore-local.sh backups/restic/${fname}"
done
echo ""
echo -e "Restore to K8s dev:"
for f in "${OUTPUT_FILES[@]}"; do
  fname="${f%% *}"
  echo -e "  ./scripts/db/restore-dev.sh backups/restic/${fname}"
done
