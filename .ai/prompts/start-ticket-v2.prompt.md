---
description: 'Comprehensive Jira ticket analysis with implementation review and documentation'
agent: 'agent'
tools: [vscode/memory, vscode/askQuestions, execute, read, agent, edit, search, web, todo]
---

# Start Ticket Analysis

## Objective

Perform a comprehensive analysis of a Jira ticket including implementation discovery, code review, status assessment, and complete documentation generation.

## Usage

```plaintext
Review this Jira ticket: <ticket_id>
```

## Examples

```plaintext
Review this Jira ticket: PROJ-5506
Review this Jira ticket: PROJ-4449
Analyze and document ticket: PROJ-123
```

---

## Instructions

Follow this comprehensive workflow to analyze the Jira ticket `<ticket_id>`:

### 1. 📋 Ticket Information Gathering

**Objective**: Extract complete ticket details and context

**Actions**:
- Fetch ticket details using Jira CLI with raw JSON output
- Parse key information: summary, description, status, assignee, reporter, labels, priority, sprint
- Extract Definition of Done (DoD) criteria
- Identify linked issues (blocks/blocked by, relates to)
- Review comments and activity history for decisions and stakeholder mentions

**Commands**:
```bash
# Get complete ticket details
jira issue view <ticket_id> --raw

# Get comments and discussions
jira issue comment list <ticket_id>
```

**Expected Output**:
- Ticket metadata (status, priority, sprint, dates)
- Full description and DoD checklist
- Stakeholders and linked issues
- Key decisions from comments

---

### 2. 🔍 Repository Discovery

**Objective**: Identify which repositories are involved in the implementation

**Actions**:
- Based on ticket component/project, identify primary repository(ies)
- Verify repository exists in local workspace
- Check repository state (current branch, clean/dirty status)
- Identify common patterns:

**Repository Mappings**:
| Ticket Component | Repository Pattern | Location |
|-----------------|-------------------|----------|
| RPA - UiPath | `ansible-ads-uipath*` | `$WORK_REPOS/` |
| Docker projects | `*-docker-*` | `$WORK_REPOS/` |
| Infrastructure | `ansible-*`, `*-terraform-*`, `*-kubernetes-*` | `$WORK_REPOS/` |

**Commands**:
```bash
# Navigate to work repositories
cd $WORK_REPOS/

# List matching repositories
ls -d *ansible* *terraform* | grep -i <keyword>

# Check repository status
cd <repository>
git fetch origin
git status
git branch --show-current
```

**Expected Output**:
- Primary repository name and path
- Current branch and status
- Whether repository is up to date

---

### 3. 🌿 Implementation Discovery

**Objective**: Find all related branches, PRs, and commits

**Actions**:
- Search for branches matching ticket ID or keywords
- Find related Pull Requests using GitHub CLI
- Search commit history for ticket references
- Check PR status (open/merged/draft) and discussions

**Commands**:
```bash
# Search branches locally
git branch -a | grep -i "<ticket_id>\|<keyword>"

# Find PRs in GitHub Enterprise
GH_HOST="$GHE_HOST" gh pr list \
  --repo <org>/<repo> \
  --state all \
  --search "<ticket_id>" \
  --json number,title,state,headRefName,url,createdAt,author

# Get PR details
GH_HOST="$GHE_HOST" gh pr view <PR_NUMBER> \
  --repo <org>/<repo> \
  --json title,body,state,files,commits,comments,reviews

# Search commit history
git log --all --oneline --grep="<ticket_id>" -i --graph --date=short --pretty=format:"%h %ad %s %an"
```

**Expected Output**:
- List of related branches (local and remote)
- PR numbers, titles, and states
- Commit SHAs and messages
- Review status and comments

---

### 4. 💻 Code Analysis

**Objective**: Review the actual implementation changes

**Actions**:
- Stash current work if repository is dirty (use descriptive message)
- Checkout the relevant branch for analysis
- Review all changed files
- Analyze key changes and their purpose
- Check configuration files for versions and prerequisites
- Review tests if present

**Commands**:
```bash
# Stash uncommitted changes (if needed)
git stash push -m "Stashing before analyzing <ticket_id>"

# Checkout target branch
git checkout <branch_name>

# View changed files
git diff main..<branch_name> --stat
git diff main..<branch_name> --name-only

# View specific file changes
git diff main..<branch_name> -- <file_path>

# Alternative: Get files from PR
GH_HOST="$GHE_HOST" gh pr diff <PR_NUMBER> --repo <org>/<repo>
```

**Files to Review**:
- Configuration files (YAML, JSON, ENV)
- Implementation files (Python, Ansible playbooks, Terraform)
- Documentation updates (README, CHANGELOG)
- Test files
- Dependency files (requirements.txt, package.json, etc.)

**Expected Output**:
- List of modified files with descriptions
- Key code changes and their purpose
- Configuration changes (versions, parameters)
- Prerequisites or dependencies

---

### 5. 📊 Status Assessment

**Objective**: Determine what's completed and what's pending

**Actions**:
- Compare DoD items against actual implementation
- Identify completed tasks (✅)
- Identify pending tasks (⏳)
- Note blockers or issues (⚠️)
- Extract required confirmations or next actions

**Analysis Checklist**:
- [ ] All DoD items addressed
- [ ] Code changes align with requirements
- [ ] Tests exist and pass
- [ ] Documentation is complete
- [ ] PR approved and ready to merge
- [ ] Deployment plan is clear
- [ ] Stakeholder approvals obtained

**Expected Output**:
- Clear status summary (% complete)
- List of completed vs pending tasks
- Identified blockers
- Required next actions

---

### 6. 📝 Generate Comprehensive Documentation

**Objective**: Create complete, actionable documentation

**Actions**:
- Create project folder: `~/REPOSITORIOS/0_PERSONAL/work/projects/lunik/<ticket_id>/`
- Generate comprehensive `README.md` with all findings
- Include exact commands for deployment/execution
- Provide troubleshooting guidance
- Link to all relevant resources

**Documentation Structure**:

```markdown
# <TICKET_ID>: <Title>

**Ticket URL**: <jira_url>
**Created**: <date> | **Updated**: <date>

## 📋 Ticket Information
- **Status**: <status>
- **Priority**: <priority>
- **Assignee**: <assignee>
- **Sprint**: <sprint>
- **Labels**: <labels>

## 🎯 Objective
<Clear one-sentence goal>

## 📝 Description
<Detailed requirements and context>

## ✅ Definition of Done
- [ ] Item 1
- [ ] Item 2
- [ ] Item 3

## 🔗 Dependencies
- **Blocks**: <linked tickets>
- **Blocked by**: <linked tickets>
- **Relates to**: <linked tickets>

## 💻 Technical Implementation

### Repository & Branch
- **Repository**: `<org>/<repo>`
- **Branch**: `<branch_name>`
- **PR**: #<pr_number> (<state>)

### Changes Made
| File | Type | Description |
|------|------|-------------|
| `path/to/file` | Modified | Description of change |

### Commit History
```
<commit_sha> <date> <message>
```

### Key Technical Details
- **Technology**: <language/framework>
- **Dependencies**: <packages/versions>
- **Prerequisites**: <requirements>

## 📊 Current Status

### ✅ Completed
- [x] Task 1
- [x] Task 2

### ⏳ Pending
- [ ] Task 3
- [ ] Task 4

### ⚠️ Blockers/Issues
- Issue 1
- Issue 2

## 🚀 Deployment Plan

### Pre-deployment Checklist
- [ ] Code reviewed and approved
- [ ] Tests pass
- [ ] Staging environment validated
- [ ] Stakeholder approval obtained
- [ ] Backup plan ready

### Execution Steps
```bash
# Step 1: Description
command1

# Step 2: Description
command2

# Step 3: Description
command3
```

### Verification Steps
1. Check X is working: `command`
2. Verify Y has changed: `command`
3. Test Z functionality: `command`

### Rollback Plan
```bash
# If deployment fails
rollback_command
```

## 📚 Technical Notes
<Important technical details, version numbers, configurations>

## 🔧 Troubleshooting

### Common Issues
| Issue | Cause | Solution |
|-------|-------|----------|
| Error X | Reason | Fix command |

## 📞 Contacts
- **Product Owner**: <name>
- **Tech Lead**: <name>
- **Stakeholders**: <names from ticket>

## 📅 Timeline
- **Created**: <date>
- **Started**: <date>
- **Target**: <date>
- **Completed**: <date>

## 🔗 Related Links
- [Jira Ticket](<jira_url>)
- [Pull Request](<pr_url>)
- [Related Documentation](<doc_url>)
- [Architecture Diagram](<diagram_url>)

## 📝 Analysis Notes
<Additional observations, recommendations, or context>
```

**Expected Output**:
- Complete README.md in ticket folder
- All sections filled with accurate information
- Actionable commands and checklists
- Clear next steps

---

### 7. 🎯 Provide Next Steps

**Objective**: Give clear, actionable recommendations

**Actions**:
- Summarize current status
- List immediate next actions
- Identify people to contact
- Highlight decisions needed
- Provide exact commands to execute

**Next Steps Format**:
1. **Action**: What needs to be done
   - **Who**: Person responsible
   - **Command**: `exact command to run`
   - **Expected result**: What should happen

**Expected Output**:
- Prioritized list of next actions
- Specific commands ready to execute
- Clear ownership of tasks

---

## Tool Requirements

### Required CLI Tools
- ✅ `jira` (Atlassian Jira CLI) - authenticated
- ✅ `gh` (GitHub CLI) - authenticated with Enterprise
- ✅ `git` - configured with repositories
- ✅ Standard shell tools: `grep`, `ls`, `cd`, `cat`

### Environment Configuration
```bash
# GitHub Enterprise host (derived from the repo remote)
export GHE_HOST="${GHE_HOST:-$(git config --get remote.origin.url | sed -E 's#.*@([^/:]+).*#\1#')}"
export GH_HOST="$GHE_HOST"

# Workspace paths
WORK_REPOS="${WORK_REPOS:-$HOME/REPOSITORIOS/1_WORK}"
DOCS_PATH="${DOCS_PATH:-$HOME/REPOSITORIOS/0_PERSONAL/work/projects/lunik}"
```

### Verify Tool Availability
```bash
# Check Jira CLI
jira --version

# Check GitHub CLI
gh --version
gh auth status

# Check Git
git --version
```

---

## Best Practices

### ✅ Do's

1. **Be Thorough**: Read actual code, not just commit messages
2. **Use Raw JSON**: Always use `--raw` flag with Jira CLI for parsing
3. **Set GH_HOST**: Always prefix GitHub Enterprise commands with `GH_HOST=$GHE_HOST`
4. **Stash Safely**: Always stash with descriptive messages before switching branches
5. **Parallel Searches**: Run independent searches simultaneously (Jira + GitHub + Git)
6. **Verify State**: Check repository state before and after operations
7. **Exact Commands**: Include exact, tested commands in documentation
8. **Link Resources**: Link to official docs and related resources
9. **Case Insensitive**: Use `grep -i` for case-insensitive searches
10. **Document Context**: Why decisions were made, not just what was done

### ❌ Don'ts

1. **Don't Guess**: If information is missing, search more or ask
2. **Don't Assume**: Verify repository locations and names
3. **Don't Leave Dirty**: Always restore repository state after analysis
4. **Don't Skip Tests**: Review test files if they exist
5. **Don't Forget Stash**: Check for stashed changes before finishing
6. **Don't Duplicate**: Reference code instead of repeating information
7. **Don't Omit Context**: Always provide why, not just what
8. **Don't Hard-code**: Use variables for paths and configurable values

---

## Error Handling

### Common Issues and Solutions

#### 1. Repository Not Found
```bash
# Verify repository exists
ls -la $WORK_REPOS/ | grep -i <repo_name>

# Check organization name
GH_HOST="$GHE_HOST" gh repo list <org>
```

#### 2. GitHub Authentication Failed
```bash
# Check auth status
gh auth status

# Re-authenticate if needed
GH_HOST="$GHE_HOST" gh auth login
```

#### 3. Branch Conflicts
```bash
# List stashes
git stash list

# View stash contents
git stash show -p stash@{0}

# Apply specific stash
git stash apply stash@{0}

# Drop stash after applying
git stash drop stash@{0}
```

#### 4. Jira Ticket Not Found
```bash
# Verify ticket ID format
# Check project key exists
jira project list

# Verify you have access
jira issue view <TICKET_ID>
```

#### 5. PR Search Returns Nothing
- Try searching by keywords instead of ticket ID
- Check if PR is in a different repository
- Look for merged PRs with `--state merged`
- Search commits directly: `git log --grep`

---

## Validation Checklist

Before completing the analysis, verify:

- [ ] ✅ Jira ticket details fully extracted
- [ ] ✅ All related repositories identified
- [ ] ✅ All PRs and branches found
- [ ] ✅ Code changes reviewed and understood
- [ ] ✅ Current status clearly documented (completed vs pending)
- [ ] ✅ Next steps are actionable and specific with exact commands
- [ ] ✅ Documentation is complete and well-structured
- [ ] ✅ Contacts and stakeholders identified
- [ ] ✅ Deployment plan with pre-flight checklist provided
- [ ] ✅ Troubleshooting guide included
- [ ] ✅ All commands tested and working
- [ ] ✅ Related links added (Jira, PRs, docs)
- [ ] ✅ Repository state restored if changed

---

## Success Criteria

A successful ticket analysis includes:

1. **Complete Information Gathering**
   - All ticket metadata extracted
   - Full DoD documented
   - Dependencies identified

2. **Thorough Code Review**
   - All changes identified and understood
   - Configuration changes documented
   - Tests reviewed

3. **Clear Status Assessment**
   - Percentage complete calculated
   - Blockers identified
   - Next actions clear

4. **Actionable Documentation**
   - Step-by-step deployment plan
   - Exact commands provided
   - Verification steps included
   - Rollback plan documented

5. **Comprehensive Context**
   - Stakeholders identified
   - Related resources linked
   - Technical decisions explained
   - Troubleshooting guide provided

---

## Integration with Existing Skills

This prompt leverages the skill defined in:
- `.github/skills/jira-ticket-analysis.md`

And follows the methodology from:
- `.github/prompts/analyze-ticket.md`

For complete background on the methodology, refer to those documents.

---

## Version History

- **v2.0** (2026-02-10): Complete rewrite with best practices from GitHub Copilot documentation
  - Added YAML frontmatter with metadata
  - Restructured with clear phases and objectives
  - Added comprehensive examples and commands
  - Included error handling and troubleshooting
  - Added validation checklist
  - Improved documentation structure
  - Added table formatting for clarity
  - Included success criteria

- **v1.0**: Initial brief version (Spanish, basic instructions)

---

## Quick Reference

### One-Line Invocation
```plaintext
Review this Jira ticket: <TICKET_ID>
```

### Full Workflow Command Set
```bash
# 1. Get ticket
jira issue view <TICKET_ID> --raw

# 2. Find PR
GH_HOST="$GHE_HOST" gh pr list --repo <org>/<repo> --search "<TICKET_ID>"

# 3. Check branches
git branch -a | grep -i "<TICKET_ID>"

# 4. Review code
git checkout <branch>
git diff main..<branch> --stat

# 5. Document
mkdir -p ~/REPOSITORIOS/0_PERSONAL/work/projects/lunik/<TICKET_ID>
# Generate README.md
```

### Key Environment Variables
```bash
export GH_HOST=$GHE_HOST
export WORK_REPOS="$HOME/REPOSITORIOS/1_WORK"
export DOCS_PATH="$HOME/REPOSITORIOS/0_PERSONAL/work/projects/lunik"
```

---

**Ready to analyze? Just say:**
```
Review this Jira ticket: <TICKET_ID>
```
