#!/usr/bin/env bash
set -euo pipefail

# Generic GHES helper: summarize git info/refs HTTP statuses from haproxy logs.
# Usage:
#   ./haproxy_git_refs_status_summary.sh /var/log/haproxy.log
#   ./haproxy_git_refs_status_summary.sh /var/log/haproxy.log "16/Mar/2026:1[89]:\|16/Mar/2026:2[0-2]:"

LOG_FILE="${1:-/var/log/haproxy.log}"
WINDOW_REGEX="${2:-}"

if [[ ! -r "$LOG_FILE" ]]; then
  echo "ERROR: cannot read log file: $LOG_FILE" >&2
  exit 1
fi

base_stream="cat \"$LOG_FILE\" | grep 'info/refs'"
if [[ -n "$WINDOW_REGEX" ]]; then
  base_stream="$base_stream | grep '$WINDOW_REGEX'"
fi

run_count() {
  local status="$1"
  eval "$base_stream | grep ' $status ' | wc -l"
}

echo "log_file=$LOG_FILE"
if [[ -n "$WINDOW_REGEX" ]]; then
  echo "window_regex=$WINDOW_REGEX"
else
  echo "window_regex=ALL"
fi

echo "total_info_refs=$(eval \"$base_stream | wc -l\")"
echo "status_200=$(run_count 200)"
echo "status_401=$(run_count 401)"
echo "status_403=$(run_count 403)"
echo "status_404=$(run_count 404)"
echo "status_5xx=$(eval \"$base_stream | grep ' 5[0-9][0-9] ' | wc -l\")"
echo "status_503=$(run_count 503)"
