# Engram shared setup

Centralized Engram launcher/checks for Windows and Linux. The goal is to keep **one source of truth** in `configLinux` for:

- VS Code MCP configuration snippets (`engram-stdio` over `stdio`)
- launching the **Engram HTTP API** + **engram-monitor**
- smoke-checking that the MCP command is launchable
- running an optional **end-to-end validation** that writes a memory, checks the API, checks the monitor proxy, and confirms the item is visible in the rendered UI

## Files

- `start-engram-stack.ps1` — Windows launcher/checker
- `start-engram-stack.sh` — Linux launcher/checker
- `check-engram-monitor-e2e.js` — shared browser-based UI verification
- `package.json` — local dependency manifest for Playwright used by the E2E check
- `mcp.windows.jsonc` — Windows VS Code MCP snippet
- `mcp.linux.jsonc` — Linux VS Code MCP snippet

## What the launcher does

1. Confirms `engram-stdio` exists in VS Code `mcp.json`
2. Smoke-tests `engram mcp --tools=agent`
3. Clones `engram-monitor` if missing
4. Patches `engram-monitor/vite.config.ts` so the proxy can follow `ENGRAM_PORT`
5. Starts `engram serve` on `7437`, or falls back to `7440+` if the preferred port is busy
6. Starts `engram-monitor` on `5173`, or the next free port
7. Optionally runs an E2E check that:
   - writes a test memory with `engram save`
   - queries the direct Engram API
   - queries the monitor proxy (`/engram-api/search`)
   - opens the monitor in a browser and verifies the token is visible in the `Memories` tab

## Prerequisites

### Common

- `engram`
- `node`
- `npm`
- `pnpm` or `corepack`
- internet access the first time `engram-monitor` is cloned or Playwright is installed

### Windows prerequisites

- `git`
- PowerShell 5.1+ (tested here on Windows)
- optional: Edge or Chrome installed for the fastest Playwright run; bundled Playwright browser is the fallback

### Linux prerequisites

- `git`
- `bash`
- `curl`
- `python3`

## VS Code configuration

Keep the MCP itself on `stdio`. Do **not** try to turn this launcher into the MCP server; the launcher is for the API + monitor sidecar stack.

### Windows VS Code

Use the snippet from `mcp.windows.jsonc` and keep a comment like this next to the MCP entry:

```jsonc
// powershell -ExecutionPolicy Bypass -File "$env:CONFIG_PATH\SCRIPTS\engram\start-engram-stack.ps1" -RunE2ECheck
"engram-stdio": {
  "type": "stdio",
  "command": "engram",
  "args": ["mcp", "--tools=agent"]
}
```

### Linux VS Code

Use the snippet from `mcp.linux.jsonc` and keep a comment like this next to the MCP entry:

```jsonc
// bash ~/configLinux/SCRIPTS/engram/start-engram-stack.sh --run-e2e-check
"engram-stdio": {
  "type": "stdio",
  "command": "engram",
  "args": ["mcp", "--tools=agent"]
}
```

Typical config paths:

- VS Code Stable: `~/.config/Code/User/mcp.json`
- VS Code Insiders: `~/.config/Code - Insiders/User/mcp.json`

## How to run

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File "$env:CONFIG_PATH\SCRIPTS\engram\start-engram-stack.ps1"
```

With the full end-to-end validation:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:CONFIG_PATH\SCRIPTS\engram\start-engram-stack.ps1" -RunE2ECheck
```

### Linux

```bash
bash ~/configLinux/SCRIPTS/engram/start-engram-stack.sh
```

With the full end-to-end validation:

```bash
bash ~/configLinux/SCRIPTS/engram/start-engram-stack.sh --run-e2e-check
```

If you want a shorter Linux entry point from the repo `bin/` folder, use:

```bash
~/configLinux/bin/engram-stack-e2e
```

That wrapper simply resolves the repo root and executes:

```bash
bash ~/configLinux/SCRIPTS/engram/start-engram-stack.sh --run-e2e-check
```

If the executable bit is not preserved on your Linux checkout, run:

```bash
chmod +x ~/configLinux/bin/engram-stack-e2e
```

## Shared monitor clone location

By default, both launchers use this location for the upstream `engram-monitor` working tree:

- Windows: `%USERPROFILE%\\engram-monitor`
- Linux: `~/engram-monitor`

You can override it with:

- Windows: `ENGRAM_MONITOR_DIR`
- Linux: `ENGRAM_MONITOR_DIR`

This keeps `configLinux` as the source of truth for scripts and docs, while the actual `engram-monitor` repository remains a normal clone outside this repo.

## Notes about `engram-monitor` modifications

The reusable launcher only **requires** one patch in `engram-monitor`:

- `vite.config.ts` must proxy `/engram-api` to `process.env.ENGRAM_PORT ?? '7437'`

That patch is applied automatically by the launcher if needed.

The current local clone keeps that modification in place. On this machine, the launcher validated it by running Engram on a non-default port (`7454`) and the monitor on `5184`, with the E2E check passing end-to-end.

If you want to upstream the change later, use the draft issue in:

- `SCRIPTS/engram/issue-engram-monitor-configurable-port.md`

### About the local `package.json` tweak used during the first Windows prototype

During the initial manual experiment, `package.json` was patched so `pnpm dev` could use `%ENGRAM_PORT%` on Windows. That was useful for proving the concept, but it is **not** the portable long-term path because:

- `%ENGRAM_PORT%` is Windows-specific
- Linux would need a different syntax
- the shared launchers here no longer depend on `pnpm dev`

Instead, the shared launchers directly run:

- `engram serve <port>`
- `pnpm exec vite --host ... --port ...`

So the only upstream change we currently need in `engram-monitor` for portability is the `vite.config.ts` proxy patch.

## Notes about Engram itself

No code change to the Engram repository was required for alternate ports.

We are relying on the supported CLI behavior already present in Engram:

- `engram serve [port]`
- `engram mcp --tools=agent`
- `engram save <title> <msg> --type ... --project ... --scope ...`

That means the reusable scripts can:

- start the API on a fallback port if `7437` is busy
- save an observation for the E2E test without depending on chat-only MCP tools

## Git identity check before committing

Before committing from another machine, verify the effective identity inside the clone:

```bash
git config --includes user.name
git config --includes user.email
```

## Logs and artifacts

The shared launchers write logs under:

- `configLinux/SCRIPTS/engram/logs/`

The E2E screenshot is stored there as well, by default:

- `engram-monitor-e2e.png`

These paths are ignored in Git via the repo `.gitignore`.
