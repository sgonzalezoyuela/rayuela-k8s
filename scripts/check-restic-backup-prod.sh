#!/usr/bin/env bash
# =============================================================================
# check-restic-backup-prod.sh - Check restic backup status from K8s CronJob
# =============================================================================
# Inspects the rayuela-db-backup CronJob and its latest Job to report
# backup health: schedule, last success time, job status, and restic
# integrity markers from the job logs.
#
# Exit codes (monitoring-friendly):
#   0 = OK        — backup is healthy and recent
#   1 = WARNING   — backup ran but has issues (e.g., restic check failed)
#   2 = CRITICAL  — backup is stale, failed, or CronJob is missing/suspended
#
# Usage:
#   ./scripts/check-restic-backup-prod.sh [OPTIONS]
#
# Options:
#   --max-age-hours <N>   Max hours since last success before CRITICAL (default: 30)
#   --show-logs           Print the full logs from the latest backup job
#   --trigger             Manually trigger a backup job and follow its logs
#   --namespace <ns>      Override namespace (default: rayuela-prod)
#   --cronjob <name>      Override CronJob name (default: rayuela-db-backup)
#   -h, --help            Show this help message
# =============================================================================

set -euo pipefail

# ─────────────────────────────────────────────────────────────────
# Defaults
# ─────────────────────────────────────────────────────────────────
NS="rayuela-prod"
CRONJOB="rayuela-db-backup"
MAX_AGE_HOURS=30
SHOW_LOGS=false
TRIGGER=false

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
  echo "  --max-age-hours <N>   Max hours since last success (default: 30)"
  echo "  --show-logs           Print full logs from the latest backup job"
  echo "  --trigger             Manually trigger a backup job and follow its logs"
  echo "  --namespace <ns>      Override namespace (default: rayuela-prod)"
  echo "  --cronjob <name>      Override CronJob name (default: rayuela-db-backup)"
  echo "  -h, --help            Show this help message"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-age-hours) MAX_AGE_HOURS="$2"; shift 2 ;;
    --show-logs)     SHOW_LOGS=true; shift ;;
    --trigger)       TRIGGER=true; shift ;;
    --namespace)     NS="$2"; shift 2 ;;
    --cronjob)       CRONJOB="$2"; shift 2 ;;
    -h|--help)       usage ;;
    *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
  esac
done

# ─────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────
STATUS="OK"
STATUS_CODE=0
ISSUES=()

downgrade_status() {
  local new="$1"
  local msg="${2:-}"
  if [[ "$new" == "CRITICAL" ]]; then
    STATUS="CRITICAL"; STATUS_CODE=2
  elif [[ "$new" == "WARNING" && "$STATUS" != "CRITICAL" ]]; then
    STATUS="WARNING"; STATUS_CODE=1
  fi
  if [[ -n "$msg" ]]; then
    ISSUES+=("$msg")
  fi
}

time_ago() {
  local ts="$1"
  if [[ -z "$ts" || "$ts" == "null" || "$ts" == "<none>" ]]; then
    echo "never"
    return
  fi
  local now_epoch ts_epoch diff_s hours mins
  now_epoch=$(date +%s)
  ts_epoch=$(date -d "$ts" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null || echo "")
  if [[ -z "$ts_epoch" ]]; then
    echo "unknown"
    return
  fi
  diff_s=$((now_epoch - ts_epoch))
  hours=$((diff_s / 3600))
  mins=$(( (diff_s % 3600) / 60 ))
  if [[ $hours -gt 0 ]]; then
    echo "${hours}h ${mins}m ago"
  else
    echo "${mins}m ago"
  fi
}

check_icon() {
  if [[ "$1" == "ok" ]]; then echo -e "${GREEN}OK${NC}"
  else echo -e "${RED}MISSING${NC}"
  fi
}

# ─────────────────────────────────────────────────────────────────
# Prerequisites
# ─────────────────────────────────────────────────────────────────
if ! command -v kubectl &>/dev/null; then
  echo -e "${RED}Error: kubectl is not installed${NC}"
  exit 2
fi

if ! kubectl cluster-info &>/dev/null 2>&1; then
  echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
  exit 2
fi

# ─────────────────────────────────────────────────────────────────
# 0. Trigger manual backup (if requested)
# ─────────────────────────────────────────────────────────────────
if [[ "$TRIGGER" == true ]]; then
  MANUAL_JOB="${CRONJOB}-manual-$(date +%s)"
  echo -e "${CYAN}Triggering manual backup job: ${MANUAL_JOB}${NC}"
  echo ""
  kubectl create job --from="cronjob/${CRONJOB}" "$MANUAL_JOB" -n "$NS"
  echo ""

  # Wait for the pod to be scheduled and the init container to finish
  echo -e "${CYAN}Waiting for pod to start...${NC}"
  for i in $(seq 1 60); do
    POD_NAME=$(kubectl get pods -n "$NS" -l "job-name=${MANUAL_JOB}" \
      -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
    if [[ -n "$POD_NAME" ]]; then
      POD_PHASE=$(kubectl get pod "$POD_NAME" -n "$NS" \
        -o jsonpath='{.status.phase}' 2>/dev/null || true)
      INIT_STATUS=$(kubectl get pod "$POD_NAME" -n "$NS" \
        -o jsonpath='{.status.initContainerStatuses[0].state.terminated.reason}' 2>/dev/null || true)
      # Pod running = init container done, main container started
      if [[ "$POD_PHASE" == "Running" || "$POD_PHASE" == "Succeeded" || "$POD_PHASE" == "Failed" ]]; then
        break
      fi
      # Show init container progress
      if [[ -n "$INIT_STATUS" ]]; then
        echo -e "  Init container: ${INIT_STATUS}"
      fi
    fi
    sleep 2
  done

  if [[ -z "$POD_NAME" ]]; then
    echo -e "${YELLOW}Warning: Could not find pod for job ${MANUAL_JOB}${NC}"
  else
    echo -e "${CYAN}Following logs from container 'backup' (Ctrl+C to detach)...${NC}"
    echo ""
    kubectl logs -f "$POD_NAME" -c backup -n "$NS" 2>/dev/null || true
  fi

  # Wait for job completion (up to 10 minutes)
  echo ""
  echo -e "${CYAN}Waiting for job to complete...${NC}"
  kubectl wait --for=condition=complete "job/${MANUAL_JOB}" -n "$NS" --timeout=600s 2>/dev/null \
    || kubectl wait --for=condition=failed "job/${MANUAL_JOB}" -n "$NS" --timeout=30s 2>/dev/null \
    || true

  echo ""
  echo -e "${CYAN}Running status check...${NC}"
  echo ""
fi

# ─────────────────────────────────────────────────────────────────
# 1. Required secrets
# ─────────────────────────────────────────────────────────────────
SECRET_DB="missing"
SECRET_RESTIC="missing"

if kubectl get secret rayuela-secrets -n "$NS" &>/dev/null; then
  SECRET_DB="ok"
else
  downgrade_status "CRITICAL" "Secret 'rayuela-secrets' (db-password) not found in ${NS}"
fi

if kubectl get secret rayuela-backup-secrets -n "$NS" &>/dev/null; then
  SECRET_RESTIC="ok"
else
  downgrade_status "CRITICAL" "Secret 'rayuela-backup-secrets' (restic-password) not found in ${NS}"
fi

# ─────────────────────────────────────────────────────────────────
# 2. CronJob metadata
# ─────────────────────────────────────────────────────────────────
if ! kubectl get cronjob "$CRONJOB" -n "$NS" &>/dev/null; then
  echo -e "${RED}CRITICAL: CronJob ${CRONJOB} not found in namespace ${NS}${NC}"
  exit 2
fi

SCHEDULE=$(kubectl get cronjob "$CRONJOB" -n "$NS" -o jsonpath='{.spec.schedule}')
TIMEZONE=$(kubectl get cronjob "$CRONJOB" -n "$NS" -o jsonpath='{.spec.timeZone}')
SUSPENDED=$(kubectl get cronjob "$CRONJOB" -n "$NS" -o jsonpath='{.spec.suspend}')
LAST_SCHEDULE=$(kubectl get cronjob "$CRONJOB" -n "$NS" -o jsonpath='{.status.lastScheduleTime}')
LAST_SUCCESS=$(kubectl get cronjob "$CRONJOB" -n "$NS" -o jsonpath='{.status.lastSuccessfulTime}')

SUSPENDED="${SUSPENDED:-false}"
TIMEZONE="${TIMEZONE:-UTC}"

if [[ "$SUSPENDED" == "true" ]]; then
  downgrade_status "CRITICAL" "CronJob is suspended"
fi

# ─────────────────────────────────────────────────────────────────
# 3. Freshness check
# ─────────────────────────────────────────────────────────────────
if [[ -z "$LAST_SUCCESS" ]]; then
  downgrade_status "CRITICAL" "No successful backup recorded"
  FRESHNESS_MSG="no successful backup recorded"
else
  NOW_EPOCH=$(date +%s)
  SUCCESS_EPOCH=$(date -d "$LAST_SUCCESS" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$LAST_SUCCESS" +%s 2>/dev/null || echo "")
  if [[ -n "$SUCCESS_EPOCH" ]]; then
    AGE_HOURS=$(( (NOW_EPOCH - SUCCESS_EPOCH) / 3600 ))
    if [[ $AGE_HOURS -ge $MAX_AGE_HOURS ]]; then
      downgrade_status "CRITICAL" "Last success was ${AGE_HOURS}h ago (threshold: ${MAX_AGE_HOURS}h)"
      FRESHNESS_MSG="last success ${AGE_HOURS}h ago (threshold: ${MAX_AGE_HOURS}h)"
    else
      FRESHNESS_MSG="last success $(time_ago "$LAST_SUCCESS") (threshold: ${MAX_AGE_HOURS}h)"
    fi
  else
    downgrade_status "WARNING" "Could not parse lastSuccessfulTime"
    FRESHNESS_MSG="could not parse lastSuccessfulTime"
  fi
fi

# ─────────────────────────────────────────────────────────────────
# 4. Latest Job status
# ─────────────────────────────────────────────────────────────────
LATEST_JOB=$(kubectl get jobs -n "$NS" \
  --sort-by='.metadata.creationTimestamp' \
  -o jsonpath='{.items[*].metadata.name}' 2>/dev/null \
  | tr ' ' '\n' | grep "^${CRONJOB}" | tail -1 || true)

JOB_STATUS_MSG="no jobs found"
JOB_SUCCEEDED=""
JOB_FAILED=""
JOB_ACTIVE=""

if [[ -n "$LATEST_JOB" ]]; then
  JOB_SUCCEEDED=$(kubectl get job "$LATEST_JOB" -n "$NS" -o jsonpath='{.status.succeeded}' 2>/dev/null || echo "")
  JOB_FAILED=$(kubectl get job "$LATEST_JOB" -n "$NS" -o jsonpath='{.status.failed}' 2>/dev/null || echo "")
  JOB_ACTIVE=$(kubectl get job "$LATEST_JOB" -n "$NS" -o jsonpath='{.status.active}' 2>/dev/null || echo "")
  JOB_CREATED=$(kubectl get job "$LATEST_JOB" -n "$NS" -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null || echo "")

  if [[ "${JOB_SUCCEEDED:-0}" -ge 1 ]]; then
    JOB_STATUS_MSG="Succeeded ($(time_ago "$JOB_CREATED"))"
  elif [[ "${JOB_ACTIVE:-0}" -ge 1 ]]; then
    JOB_STATUS_MSG="Running (started $(time_ago "$JOB_CREATED"))"
  elif [[ "${JOB_FAILED:-0}" -ge 1 ]]; then
    JOB_STATUS_MSG="Failed ($(time_ago "$JOB_CREATED"))"
    downgrade_status "CRITICAL" "Latest job ${LATEST_JOB} failed"
  else
    JOB_STATUS_MSG="Unknown"
    downgrade_status "WARNING" "Latest job ${LATEST_JOB} has unknown status"
  fi
else
  downgrade_status "WARNING" "No backup jobs found"
fi

# ─────────────────────────────────────────────────────────────────
# 5. Restic markers from logs
# ─────────────────────────────────────────────────────────────────
RESTIC_STATUS="n/a"
RESTIC_INTEGRITY="n/a"
DUMP_SIZE="n/a"
JOB_LOGS=""

if [[ -n "$LATEST_JOB" ]]; then
  JOB_LOGS=$(kubectl logs "job/$LATEST_JOB" -n "$NS" --tail=200 2>/dev/null || true)

  if [[ -n "$JOB_LOGS" ]]; then
    # Check for backup completion
    if echo "$JOB_LOGS" | grep -q "Backup completed successfully"; then
      RESTIC_STATUS="completed"
    elif echo "$JOB_LOGS" | grep -q "ERROR"; then
      RESTIC_STATUS="error"
      downgrade_status "CRITICAL" "Backup logs contain ERROR"
    elif [[ "${JOB_ACTIVE:-0}" -ge 1 ]]; then
      RESTIC_STATUS="running"
    else
      RESTIC_STATUS="unknown"
      downgrade_status "WARNING" "Could not determine restic backup result from logs"
    fi

    # Check repository integrity
    if echo "$JOB_LOGS" | grep -q "Repository integrity verified"; then
      RESTIC_INTEGRITY="verified"
    elif echo "$JOB_LOGS" | grep -q "no errors were found"; then
      RESTIC_INTEGRITY="verified"
    elif echo "$JOB_LOGS" | grep -qi "error.*check\|check.*error\|integrity.*fail"; then
      RESTIC_INTEGRITY="FAILED"
      downgrade_status "WARNING" "Restic integrity check failed"
    fi

    # Extract dump size
    SIZE_LINE=$(echo "$JOB_LOGS" | grep -oP 'Created rayuela\.dump \(\K[^)]+' || true)
    if [[ -n "$SIZE_LINE" ]]; then
      DUMP_SIZE="$SIZE_LINE"
    fi
  fi
fi

# ─────────────────────────────────────────────────────────────────
# 6. Report
# ─────────────────────────────────────────────────────────────────
case "$STATUS" in
  OK)       STATUS_COLOR="${GREEN}" ;;
  WARNING)  STATUS_COLOR="${YELLOW}" ;;
  CRITICAL) STATUS_COLOR="${RED}" ;;
esac

echo ""
echo -e "${BOLD}=========================================="
echo -e "Rayuela Backup Status Check"
echo -e "==========================================${NC}"
echo ""
echo -e "  Status:           ${STATUS_COLOR}${STATUS}${NC}"
echo -e "  CronJob:          ${CRONJOB} (${NS})"
echo -e "  Schedule:         ${SCHEDULE} (${TIMEZONE})"
echo -e "  Suspended:        ${SUSPENDED}"
echo ""
echo -e "${BOLD}── Prerequisites ───────────────────────${NC}"
echo -e "  rayuela-secrets:         $(check_icon "$SECRET_DB")"
echo -e "  rayuela-backup-secrets:  $(check_icon "$SECRET_RESTIC")"
echo ""
echo -e "${BOLD}── Timing ──────────────────────────────${NC}"
echo -e "  Last scheduled:   ${LAST_SCHEDULE:-never} ($(time_ago "${LAST_SCHEDULE:-}"))"
echo -e "  Last successful:  ${LAST_SUCCESS:-never} ($(time_ago "${LAST_SUCCESS:-}"))"
echo -e "  Freshness:        ${FRESHNESS_MSG}"
echo ""
echo -e "${BOLD}── Latest Job ──────────────────────────${NC}"
echo -e "  Job:              ${LATEST_JOB:-none}"
echo -e "  Job status:       ${JOB_STATUS_MSG}"
echo ""
echo -e "${BOLD}── Restic ──────────────────────────────${NC}"
echo -e "  Backup:           ${RESTIC_STATUS}"
echo -e "  Integrity check:  ${RESTIC_INTEGRITY}"
echo -e "  Dump size:        ${DUMP_SIZE}"
echo ""

if [[ ${#ISSUES[@]} -gt 0 ]]; then
  echo -e "${BOLD}── Issues ──────────────────────────────${NC}"
  for issue in "${ISSUES[@]}"; do
    echo -e "  ${RED}•${NC} ${issue}"
  done
  echo ""
fi

if [[ "$SHOW_LOGS" == true && -n "$JOB_LOGS" ]]; then
  echo -e "${BOLD}── Job Logs ────────────────────────────${NC}"
  echo "$JOB_LOGS"
  echo ""
fi

exit "$STATUS_CODE"
