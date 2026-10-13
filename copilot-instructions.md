# GitHub Copilot Instructions

## General Rules
- Always write clean, maintainable, and well-documented code
- Follow DRY (Don't Repeat Yourself) and KISS (Keep It Simple) practices
- Prefer simple solutions over complex ones

## Terminal & Command Execution

### IMPORTANT: Terminal Commands

**NEVER attempt to execute commands with `sudo` directly.** VS Code blocks automatic execution of commands requiring elevated privileges by security.

If a command requires `sudo`:
1. Notify the user that the command needs root permissions
2. Clearly indicate the exact command that needs to be run manually
3. DO NOT attempt to use `autoApprove` for commands with `sudo`

Example of correct behavior:
```
❌ INCORRECT: run_in_terminal(command: "sudo apt install -y package")
✅ CORRECT: "This command needs root permissions. Please manually run:
   sudo apt install -y package
```

### Allowed Terminal Commands

**No permission required (auto-execute):**
- `npm`, `npx`, `yarn`, `pnpm`
- `python`, `pip`, `python3`, `pip3`
- `git` (read-only commands and local changes)
- `ls`, `cat`, `echo`, `pwd`, `cd`
- `find`, `grep`
- `curl`, `wget` (without redirecting to config files)

**Require user confirmation:**
- `chmod`, `chown`
- `mkdir -p` in system directories
- `apt`, `apt-get`, `dnf`, `yum`, `pacman` (package managers)
- `docker` (in some contexts)
- `rm -rf`
- Any command that modifies system configuration

**NEVER request:**
- `sudo` any command
- Commands that modify `/etc/`, `/usr/`, `/var/`

## Code Style
- [Adjust according to your project]
- [Use TypeScript strict mode]
- [Prefer async/await over callbacks]

## Documentation
- [Adjust according to your project]
- [Document public functions with JSDoc]

## Testing
- [Adjust according to your project]
- [Write unit tests for new features]

## MCP Configuration
- If you need to check MCP server status:
  ```
  find ~/.vscode-server/data/ -name "mcp.json" 2>/dev/null
  ```
- Do not attempt to run `gh` with sudo