#!/usr/bin/env bash
set -euo pipefail

PREFERRED_ENGRAM_PORT="${PREFERRED_ENGRAM_PORT:-7437}"
FALLBACK_ENGRAM_PORT="${FALLBACK_ENGRAM_PORT:-7440}"
PREFERRED_MONITOR_PORT="${PREFERRED_MONITOR_PORT:-5173}"
BIND_HOST="${BIND_HOST:-127.0.0.1}"
MONITOR_DIR="${ENGRAM_MONITOR_DIR:-$HOME/engram-monitor}"
MONITOR_REPO_URL="${ENGRAM_MONITOR_REPO_URL:-https://github.com/egdev6/engram-monitor.git}"
MCP_CONFIG_PATH="${ENGRAM_MCP_CONFIG_PATH:-$HOME/.config/Code - Insiders/User/mcp.json}"
E2E_PROJECT="${ENGRAM_E2E_PROJECT:-configlinux}"
RUN_E2E_CHECK=0

for arg in "$@"; do
  case "$arg" in
    --run-e2e-check)
      RUN_E2E_CHECK=1
      ;;
  esac
done

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="$SCRIPT_ROOT/logs"
E2E_SCREENSHOT_PATH="$LOGS_DIR/engram-monitor-e2e.png"
mkdir -p "$LOGS_DIR"

write_step() { printf '\n== %s ==\n' "$1"; }
write_warn() { printf '%s\n' "$1" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    write_warn "Missing required command: $1"
    exit 1
  }
}

http_ok() {
  local url="$1"
  curl -fsS --max-time 3 "$url" >/dev/null 2>&1
}

test_engram_health() {
  http_ok "http://${BIND_HOST}:$1/health"
}

test_monitor_ui() {
  curl -fsS --max-time 3 "http://${BIND_HOST}:$1/" | grep -q '<div id="root">'
}

port_is_free() {
  python3 - "$1" <<'PY'
import socket, sys
port = int(sys.argv[1])
s = socket.socket()
try:
    s.bind(('127.0.0.1', port))
except OSError:
    sys.exit(1)
finally:
    s.close()
PY
}

wait_for() {
  local seconds="$1"
  local description="$2"
  shift 2
  for _ in $(seq 1 "$seconds"); do
    if "$@"; then
      return 0
    fi
    sleep 1
  done
  write_warn "$description"
  return 1
}

ensure_monitor_repo() {
  if [[ -f "$MONITOR_DIR/package.json" && -f "$MONITOR_DIR/vite.config.ts" ]]; then
    return 0
  fi
  require_cmd git
  mkdir -p "$(dirname "$MONITOR_DIR")"
  write_step "Cloning engram-monitor into $MONITOR_DIR"
  git clone "$MONITOR_REPO_URL" "$MONITOR_DIR"
}

ensure_monitor_proxy_patch() {
  python3 - "$MONITOR_DIR/vite.config.ts" <<'PY'
from pathlib import Path
import re, sys
path = Path(sys.argv[1])
content = path.read_text()
updated = content
needle = "const engramPort = process.env.ENGRAM_PORT ?? '7437';"
if needle not in updated:
    updated = updated.replace("import svgr from 'vite-plugin-svgr';\n", "import svgr from 'vite-plugin-svgr';\n\n" + needle + "\n")
updated = re.sub(r"target:\s*'http://127\\.0\\.0\\.1:7437'", "target: `http://127.0.0.1:${engramPort}`", updated)
if updated != content:
    path.write_text(updated)
PY
}

ensure_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    echo pnpm
    return 0
  fi
  require_cmd corepack
  corepack enable pnpm >/dev/null
  if command -v pnpm >/dev/null 2>&1; then
    echo pnpm
    return 0
  fi
  write_warn 'Unable to enable pnpm via Corepack.'
  exit 1
}

ensure_playwright() {
  if [[ -d "$SCRIPT_ROOT/node_modules/playwright" ]]; then
    return 0
  fi
  write_step 'Installing local Playwright dependency for E2E checks'
  (cd "$SCRIPT_ROOT" && npm install)
}

ensure_monitor_repo
ensure_monitor_proxy_patch
require_cmd engram
require_cmd node
require_cmd npm
require_cmd curl
require_cmd python3
PNPM_BIN="$(ensure_pnpm)"

write_step 'Checking MCP stdio configuration'
MCP_STATUS='No active Engram MCP entry found in VS Code mcp.json'
MCP_SERVER='not configured'
MCP_TRANSPORT='unknown'
MCP_URL='N/A (VS Code lo usa por stdio)'
MCP_COMMAND='N/A'
if [[ -f "$MCP_CONFIG_PATH" ]] && grep -q '"engram-stdio"' "$MCP_CONFIG_PATH"; then
  MCP_STATUS='OK (active `engram-stdio` entry found in VS Code mcp.json)'
  MCP_SERVER='engram-stdio'
  MCP_TRANSPORT='stdio'
  MCP_COMMAND='engram mcp --tools=agent'
fi
printf '%s\n' "$MCP_STATUS"

write_step 'Checking MCP stdio launchability'
ENGRAM_MCP_STDOUT="$LOGS_DIR/engram-mcp-smoke.out.log"
ENGRAM_MCP_STDERR="$LOGS_DIR/engram-mcp-smoke.err.log"
set +e
engram mcp --tools=agent >"$ENGRAM_MCP_STDOUT" 2>"$ENGRAM_MCP_STDERR" &
MCP_PID=$!
sleep 2
if kill -0 "$MCP_PID" >/dev/null 2>&1; then
  kill "$MCP_PID" >/dev/null 2>&1 || true
  MCP_SMOKE='OK (launchable)'
else
  MCP_SMOKE='FAILED'
fi
set -e
printf 'MCP stdio smoke test: %s\n' "$MCP_SMOKE"

write_step 'Ensuring engram-monitor dependencies'
if [[ ! -d "$MONITOR_DIR/node_modules" ]]; then
  (cd "$MONITOR_DIR" && "$PNPM_BIN" install --ignore-scripts)
fi

write_step 'Resolving Engram API port'
ENGRAM_PORT=''
for port in $(seq "$PREFERRED_ENGRAM_PORT" "$PREFERRED_ENGRAM_PORT"); do
  if test_engram_health "$port"; then
    ENGRAM_PORT="$port"
    break
  fi
done
if [[ -z "$ENGRAM_PORT" ]]; then
  for port in $(seq "$FALLBACK_ENGRAM_PORT" $((FALLBACK_ENGRAM_PORT + 10))); do
    if test_engram_health "$port"; then
      ENGRAM_PORT="$port"
      break
    fi
  done
fi
ENGRAM_STARTED=0
if [[ -z "$ENGRAM_PORT" ]]; then
  if port_is_free "$PREFERRED_ENGRAM_PORT"; then
    ENGRAM_PORT="$PREFERRED_ENGRAM_PORT"
  else
    for port in $(seq "$FALLBACK_ENGRAM_PORT" $((FALLBACK_ENGRAM_PORT + 10))); do
      if port_is_free "$port"; then
        ENGRAM_PORT="$port"
        break
      fi
    done
  fi
  [[ -n "$ENGRAM_PORT" ]] || { write_warn 'No free Engram port found.'; exit 1; }
  nohup engram serve "$ENGRAM_PORT" >"$LOGS_DIR/engram-serve-$ENGRAM_PORT.out.log" 2>"$LOGS_DIR/engram-serve-$ENGRAM_PORT.err.log" &
  ENGRAM_STARTED=1
  wait_for 30 "Engram API did not become healthy on port $ENGRAM_PORT" test_engram_health "$ENGRAM_PORT"
else
  printf 'Engram API already healthy on %s\n' "$ENGRAM_PORT"
fi

write_step 'Resolving monitor port'
MONITOR_PORT=''
for port in $(seq "$PREFERRED_MONITOR_PORT" $((PREFERRED_MONITOR_PORT + 10))); do
  if test_monitor_ui "$port"; then
    MONITOR_PORT="$port"
    break
  fi
  if port_is_free "$port"; then
    MONITOR_PORT="$port"
    break
  fi
done
[[ -n "$MONITOR_PORT" ]] || { write_warn 'No usable monitor port found.'; exit 1; }

MONITOR_STARTED=0
if ! test_monitor_ui "$MONITOR_PORT"; then
  nohup env ENGRAM_PORT="$ENGRAM_PORT" "$PNPM_BIN" exec vite --host "$BIND_HOST" --port "$MONITOR_PORT" --strictPort >"$LOGS_DIR/engram-monitor-$MONITOR_PORT.out.log" 2>"$LOGS_DIR/engram-monitor-$MONITOR_PORT.err.log" < /dev/null &
  MONITOR_STARTED=1
  wait_for 60 "engram-monitor did not become reachable on port $MONITOR_PORT" test_monitor_ui "$MONITOR_PORT"
else
  printf 'Monitor already responding on %s\n' "$MONITOR_PORT"
fi

E2E_STATUS='skipped (use --run-e2e-check)'
E2E_TOKEN=''
E2E_DIRECT=0
E2E_PROXY=0
if [[ "$RUN_E2E_CHECK" -eq 1 ]]; then
  write_step 'Running end-to-end Engram save/API/monitor validation'
  ensure_playwright
  E2E_TOKEN="ENGRAM-E2E-$(date -u +%Y%m%d-%H%M%S)"
  engram save "$E2E_TOKEN" 'Portable E2E seed created by configLinux start-engram-stack.sh' --type manual --project "$E2E_PROJECT" --scope project
  E2E_DIRECT="$(python3 - <<PY
import json, urllib.parse, urllib.request
token = urllib.parse.quote('$E2E_TOKEN')
data = json.load(urllib.request.urlopen(f'http://$BIND_HOST:$ENGRAM_PORT/search?q={token}&limit=10'))
print(len(data))
PY
)"
  E2E_PROXY="$(python3 - <<PY
import json, urllib.parse, urllib.request
token = urllib.parse.quote('$E2E_TOKEN')
data = json.load(urllib.request.urlopen(f'http://$BIND_HOST:$MONITOR_PORT/engram-api/search?q={token}&limit=10'))
print(len(data))
PY
)"
  [[ "$E2E_DIRECT" -gt 0 ]] || { write_warn 'Direct API did not return the E2E token.'; exit 1; }
  [[ "$E2E_PROXY" -gt 0 ]] || { write_warn 'Monitor proxy did not return the E2E token.'; exit 1; }
  ENGRAM_MONITOR_URL="http://$BIND_HOST:$MONITOR_PORT/" ENGRAM_E2E_TOKEN="$E2E_TOKEN" ENGRAM_E2E_SCREENSHOT="$E2E_SCREENSHOT_PATH" ENGRAM_LOGS_DIR="$LOGS_DIR" node "$SCRIPT_ROOT/check-engram-monitor-e2e.js"
  E2E_STATUS='OK'
fi

write_step 'Summary'
printf 'Script path        : %s\n' "$0"
printf 'Engram API         : http://%s:%s/health\n' "$BIND_HOST" "$ENGRAM_PORT"
printf 'Monitor UI         : http://%s:%s/\n' "$BIND_HOST" "$MONITOR_PORT"
printf 'Monitor repo       : %s\n' "$MONITOR_DIR"
printf 'MCP server         : %s\n' "$MCP_SERVER"
printf 'MCP transport      : %s\n' "$MCP_TRANSPORT"
printf 'MCP URL            : %s\n' "$MCP_URL"
printf 'MCP in VS Code     : %s\n' "$MCP_STATUS"
printf 'MCP config path    : %s\n' "$MCP_CONFIG_PATH"
printf 'MCP command        : %s\n' "$MCP_COMMAND"
printf 'MCP smoke test     : %s\n' "$MCP_SMOKE"
printf 'E2E check          : %s\n' "$E2E_STATUS"
if [[ "$RUN_E2E_CHECK" -eq 1 ]]; then
  printf 'E2E token          : %s\n' "$E2E_TOKEN"
  printf 'E2E API hits       : %s\n' "$E2E_DIRECT"
  printf 'E2E proxy hits     : %s\n' "$E2E_PROXY"
  printf 'E2E screenshot     : %s\n' "$E2E_SCREENSHOT_PATH"
fi
printf 'Logs               : %s\n' "$LOGS_DIR"

if [[ "$ENGRAM_STARTED" -eq 1 || "$MONITOR_STARTED" -eq 1 ]]; then
  write_warn 'Note: this script validates that the MCP command is launchable, but only VS Code can make it truly active/attached.'
fi