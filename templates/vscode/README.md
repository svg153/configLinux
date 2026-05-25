# VS Code agent templates

This folder stores user-level agent assets that are worth bootstrapping on a new machine.

## What is included

- `mcp.jsonc` — sanitized MCP server template based on the current active setup
- `prompts/` — reusable prompt and agent markdown files for VS Code chat

## What is not included

- `User/mcp/*` gallery seed directories
- secrets or local personal paths
- hooks (none were detected in the current VS Code Insiders user config)

The seed/cache directories under `Code - Insiders/User/mcp/` are treated as runtime/editor state, not as versioned source of truth.
