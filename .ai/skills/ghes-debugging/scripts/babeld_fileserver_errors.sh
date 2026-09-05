#!/usr/bin/env bash
set -euo pipefail

# Generic GHES helper: detect babeld signatures related to backend file server/proxy issues.
# Usage:
#   ./babeld_fileserver_errors.sh /var/log/babeld/babeld.log
#   ./babeld_fileserver_errors.sh /var/log/babeld/babeld.log "16/Mar/2026:18:"

LOG_FILE="${1:-/var/log/babeld/babeld.log}"
WINDOW_FILTER="${2:-}"

if [[ ! -r "$LOG_FILE" ]]; then
  echo "ERROR: cannot read log file: $LOG_FILE" >&2
  exit 1
fi

echo "log_file=$LOG_FILE"
if [[ -n "$WINDOW_FILTER" ]]; then
  echo "window_filter=$WINDOW_FILTER"
  stream="grep '$WINDOW_FILTER' \"$LOG_FILE\""
else
  echo "window_filter=ALL"
  stream="cat \"$LOG_FILE\""
fi

echo
echo "== key signatures count =="
echo -n "short_read="
eval "$stream | grep -i 'failed to read HTTP proxy response: short read' | wc -l"
echo -n "fileserver_connection_error="
eval "$stream | grep -i 'FileServerConnectionError' | wc -l"
echo -n "failed_initial_git_chunk="
eval "$stream | grep -i 'failed to write initial git chunk' | wc -l"
echo -n "status_503_mentions="
eval "$stream | grep -i 'status_code=\"503\"' | wc -l"

echo
echo "== sample lines (last 40) =="
eval "$stream | grep -Ei 'short read|FileServerConnectionError|failed to write initial git chunk|status_code=\"503\"' | tail -n 40"
