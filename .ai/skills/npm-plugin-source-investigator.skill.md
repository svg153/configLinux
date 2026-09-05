# Skill: NPM Plugin Source Investigator

**Purpose**: Investigate NPM package source code to understand behavior and find root causes

**When to use**:
- Plugin documentation is incomplete
- Unexpected behavior in CI/CD
- Need to understand hardcoded defaults or limitations

## Investigation Steps

### 1. Locate Plugin in node_modules
```bash
PLUGIN_NAME="@codedependant/semantic-release-docker"
PLUGIN_PATH="node_modules/$PLUGIN_NAME"

# Verify installation
ls -la "$PLUGIN_PATH"
cat "$PLUGIN_PATH/package.json" | jq -r '.version, .main'
```

### 2. Map Package Structure
```bash
cd "$PLUGIN_PATH"

# Find entry point
MAIN_FILE=$(jq -r '.main // "index.js"' package.json)
echo "Entry: $MAIN_FILE"

# List key directories
tree -L 2 -d .

# Find implementation files
find . -name "*.js" -not -path "*/node_modules/*" | head -20
```

### 3. Search for Specific Behavior

**Example: Find network-related code**
```bash
# Case-insensitive search
grep -ri "network" . --include="*.js" --exclude-dir=node_modules

# With context
grep -ri "network" . --include="*.js" -B 3 -A 3 --exclude-dir=node_modules
```

**Example: Find default values**
```bash
grep -rn "default.*=" lib/ | grep -i "network\|platform\|docker"
```

### 4. Analyze Key Functions

**Identify critical paths**:
```bash
# Build command generation
grep -rn "build.*cmd\|buildx.*cmd" lib/

# Configuration merging
grep -rn "buildConfig\|applyDefaults" lib/

# Docker execution
grep -rn "execa.*docker\|spawn.*docker" lib/
```

### 5. Read Critical Files

**Priority order**:
1. Entry point (`index.js`)
2. Build config (`lib/build-config.js`)
3. Docker implementation (`lib/docker/image.js`)
4. Plugin lifecycle (`lib/{prepare,publish,verify}.js`)

```bash
# Read with line numbers
cat -n lib/docker/image.js | less

# Extract specific function
sed -n '/^function buildCmd/,/^}/p' lib/docker/image.js
```

### 6. Check Test Cases

Tests often reveal expected behavior:
```bash
# Find test files
find . -name "*.test.js" -o -name "*.spec.js" -o -path "*/test/*"

# Search for network-related tests
grep -rn "network" test/ --include="*.js" -B 2 -A 5
```

### 7. Review CHANGELOG

```bash
# Find breaking changes
cat CHANGELOG.md | grep -i "BREAKING\|network\|buildx" -B 2 -A 2

# Check recent versions
cat CHANGELOG.md | head -100
```

### 8. Search GitHub Issues

```bash
# Using gh CLI
gh search issues --repo owner/repo "network buildx" --limit 10

# Search code in repo
gh search code --repo owner/repo "dockerNetwork default"
```

## Analysis Template

```markdown
## Plugin: [NAME] v[VERSION]

### Key Files
- Entry: [file]
- Build Logic: [file]
- Config: [file]

### Problematic Code
**File**: `[path]`
**Lines**: [X-Y]
```javascript
// Paste relevant code
```

**Issue**: [What's wrong]

### Hardcoded Values
- `dockerNetwork`: default = `"default"` (line X)
- `dockerPlatform`: default = `null` (line Y)

### How Config Flows
1. User config → `[function1]`
2. Merge with defaults → `[function2]`
3. Generate command → `[function3]`
4. Execute → `[function4]`

### Workarounds
1. [Option 1]: Why it works/doesn't work
2. [Option 2]: Trade-offs

### Upstream Contribution
- [ ] Issue exists: [link]
- [ ] Can we submit PR?
- [ ] Alternative approach?
```

## Common Patterns to Look For

### Default Values
```javascript
// Often in config files
param = param || 'default'
param: value = 'default'
const DEFAULT_X = 'value'
```

### Command Building
```javascript
// Watch for hardcoded flags
cmd.push('--flag=value')
`--flag=${this.value}`  // Template literals
```

### Conditional Logic
```javascript
// Environment-specific behavior
if (this.is_buildx) { }
if (platform.length) { }
if (process.env.CI) { }
```

## Output Format

Document findings in:
- README with issue description
- Comments in local override/patch
- GitHub issue with reproduction case

## Related Skills
- `docker-buildx-debugger.skill`
- `github-issue-researcher.skill`
