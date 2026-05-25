# Agent tooling audit and bootstrap notes

This note captures the agent-related setup that was detected on the current machine and how it is now represented in the repo.

## What was detected

### Active MCP servers in the current VS Code Insiders user config

The current `User/mcp.json` includes active entries for:

- GitHub MCP
- Context7
- Microsoft Learn
- MarkItDown MCP via Docker
- MCP documentation endpoint
- Playwright (Docker and remote HTTP variants)
- YouTube search MCP
- Vercel MCP
- Supabase MCP
- Sequential thinking via Docker
- Stitch MCP over HTTP
- Engram MCP over stdio

There are also commented/local examples for WSL-based custom MCPs. Those were **not** copied verbatim because they included machine-specific paths and local conventions.

### MCP gallery seed/cache directories detected

Detected under `Code - Insiders/User/mcp/`:

- `chromedevtools.chrome-devtools-mcp-0.0.1-seed`
- `cognitionai.deepwiki-1.0.0`
- `firecrawl.firecrawl-mcp-server-1.0.0`
- `github-0.0.1`
- `microsoft.clarity-mcp-server-1.0.0`
- `microsoft.devbox-mcp-server-1.0.0`
- `microsoft.markitdown-1.0.0`
- `microsoftdocs.mcp-1.0.0`
- `oraios.serena-1.0.0`

These directories are treated as runtime/editor cache, not as versioned bootstrap source.

### Prompt/agent files detected

Detected under `Code - Insiders/User/prompts/`:

- `code.instructions.md`
- `pr-fix.prompt.md`
- `test-agent.agent.md`
- `to-pr.prompt.md`

### Hooks

No explicit hooks configuration was detected in the current VS Code Insiders user folder during this audit.

## How the repo models this now

- `templates/vscode/mcp.jsonc` — sanitized MCP template
- `templates/vscode/prompts/*` — sanitized prompt/agent templates
- `SCRIPTS/bootstrap/linux-ai.sh` — Linux-side AI/agent bootstrap helpers

The bootstrap intentionally keeps:

- secrets out of the repo
- personal and work local paths out of the repo
- MCP gallery/cache directories out of the repo

## Intended bootstrap flows

- Linux: install agent stack via the AI stage and copy VS Code agent templates locally
- Windows: copy VS Code agent templates as part of shell/editor configuration

If a future machine has additional hooks or agent assets worth preserving, add them first as sanitized templates under `templates/vscode/` and then wire them into the entrypoints.
