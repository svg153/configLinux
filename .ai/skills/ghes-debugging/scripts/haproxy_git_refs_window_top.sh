#!/usr/bin/env bash
set -euo pipefail

# Generic GHES helper: top repos and source IPs with HTTP 503 on git info/refs.
# Usage:
#   ./haproxy_git_refs_window_top.sh /var/log/haproxy.log "16/Mar/2026:1[89]:\|16/Mar/2026:2[0-2]:" 20

LOG_FILE="${1:-/var/log/haproxy.log}"
WINDOW_REGEX="${2:-}"
LIMIT="${3:-20}"

if [[ ! -r "$LOG_FILE" ]]; then
  echo "ERROR: cannot read log file: $LOG_FILE" >&2
  exit 1
fi

if [[ -z "$WINDOW_REGEX" ]]; then
  echo "ERROR: window regex required (example: 16/Mar/2026:1[89]:\\|16/Mar/2026:2[0-2]:)" >&2
  exit 2
fi

echo "log_file=$LOG_FILE"
echo "window_regex=$WINDOW_REGEX"
echo "limit=$LIMIT"

echo
echo "== top repos with 503 info/refs =="
grep ' 503 ' "$LOG_FILE" | grep 'info/refs' | grep "$WINDOW_REGEX" | tr ' ' '\n' | grep '.git/info/refs?service=git-' | sed 's/\?.*//' | sort | uniq -c | sort -nr | head -n "$LIMIT"

echo
echo "== top source IPs with 503 info/refs =="
grep ' 503 ' "$LOG_FILE" | grep 'info/refs' | grep "$WINDOW_REGEX" | tr -s ' ' | cut -d' ' -f6 | cut -d: -f1 | sort | uniq -c | sort -nr | head -n "$LIMIT"
