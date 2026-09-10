#!/bin/bash

# Script to display Git repository status in a table format
# Usage: git-status-table.sh [DIRECTORY]
# Dependencies: gum (https://github.com/charmbracelet/gum)

# shellcheck shell=bash
# SC2155: `local x=$(cmd)` is intentional - failures are handled explicitly below.
# SC1083: @{upstream} is git's upstream shorthand, not a brace expansion.
# shellcheck disable=SC2155,SC1083

set -uo pipefail

# Colors
RED=196
GREEN=46
YELLOW=226
BLUE=39
GRAY=240
ORANGE=208

# Temporary files (global so the EXIT trap can still see them)
TEMP_RECORDS=""
TEMP_CSV=""
REPOS_FILE=""

cleanup() {
    rm -f "$TEMP_RECORDS" "$TEMP_CSV" "$REPOS_FILE"
}

# Check if gum is installed
check_gum() {
    if ! command -v gum &> /dev/null; then
        echo "❌ Error: gum is not installed."
        echo "Install it with:"
        echo "  - macOS: brew install gum"
        echo "  - Linux: sudo mkdir -p /etc/apt/keyrings"
        echo "           curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg"
        echo "           echo \"deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *\" | sudo tee /etc/apt/sources.list.d/charm.list"
        echo "           sudo apt update && sudo apt install gum"
        echo "  - Or download from: https://github.com/charmbracelet/gum/releases"
        exit 1
    fi
}

# Convert a value into a single safe CSV field.
# Commas, quotes and newlines are escaped so a commit message can never
# break the row layout consumed by `gum table`.
csv_escape() {
    local value="${1//$'\n'/ }"
    if [[ "$value" == *","* || "$value" == *"\""* ]]; then
        value="${value//\"/\"\"}"
        echo "\"$value\""
    else
        echo "$value"
    fi
}

# Use an ASCII field separator for internal storage: commit messages
# always contain commas but virtually never a control character (0x1f).
readonly FS_CHAR=$'\x1f'

# Directories that may contain vendored/cached copies of other repositories.
# Their .git folders are not projects of their own, so they are skipped.
VENDOR_DIRS=(.terraform node_modules .venv vendor bower_components .tox .gradle
             Pods .bundle .cargo target .pytest_cache __pycache__)

# Build the find expression list used to prune the vendor directories above
build_vendor_prune() {
    local expr=""
    local dir
    for dir in "${VENDOR_DIRS[@]}"; do
        [ -n "$expr" ] && expr+=" -o "
        expr+="-name $dir"
    done
    echo "$expr"
}

# Escape a value before it goes through `gum style`, so that ANSI colouring
# does not mangle the separator-based parsing done by the caller.
field_escape() {
    local value="$1"
    value="${value//$'\n'/ }"
    echo "${value//$FS_CHAR/ }"
}

# Get current branch name
get_branch() {
    git branch --show-current 2>/dev/null || echo "N/A"
}

# Count file changes
get_changes() {
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
    local modified=$(git diff --name-only 2>/dev/null | wc -l)
    local staged=$(git diff --cached --name-only 2>/dev/null | wc -l)
    echo "$modified:$staged:$untracked"
}

# Get remote status (ahead/behind) and remote domain
get_remote_status() {
    if ! git rev-parse --abbrev-ref @{upstream} &>/dev/null; then
        echo "⚠ No remote:-"
        return
    fi

    local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
    local behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    local domain="-"

    # Extract domain from remote URL
    if [ -n "$remote_url" ]; then
        if [[ "$remote_url" =~ ^git@([^:]+): ]]; then
            domain="${BASH_REMATCH[1]}"
        elif [[ "$remote_url" =~ ^https?://([^/]+) ]]; then
            domain="${BASH_REMATCH[1]}"
        fi
    fi

    local status="✓ Sync"
    if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
        status="↕ $ahead↑ $behind↓"
    elif [ "$ahead" -gt 0 ]; then
        status="↑ $ahead"
    elif [ "$behind" -gt 0 ]; then
        status="↓ $behind"
    fi

    echo "$status:$domain"
}

# Get last commit message
get_last_commit() {
    local last_commit=$(git log -1 --pretty=format:"%s" 2>/dev/null | cut -c1-40)
    [ -z "$last_commit" ] && last_commit="No commits"
    echo "$last_commit"
}

# Get the epoch of the last commit, used to sort repositories newest first.
# Repositories without commits return 0 so they land at the bottom of the
# table instead of showing a misleading "now" at the top.
get_last_modified() {
    local epoch=$(git log -1 --pretty=format:"%ct" 2>/dev/null)
    echo "${epoch:-0}"
}

# Turn an epoch into a compact age (3d, 2mo, 1y). A constant dash keeps the
# column width stable so the table stays aligned for repositories with no commits.
format_age() {
    local epoch="$1"
    if [ "$epoch" -le 0 ]; then
        echo "-"
        return
    fi

    local now=$(date +%s)
    local diff=$((now - epoch))
    [ "$diff" -lt 0 ] && diff=0

    local minute=60 hour=3600 day=86400
    if [ "$diff" -lt "$minute" ]; then
        echo "now"
    elif [ "$diff" -lt "$hour" ]; then
        echo "$((diff / minute))m"
    elif [ "$diff" -lt "$day" ]; then
        echo "$((diff / hour))h"
    elif [ "$diff" -lt "$((day * 30))" ]; then
        echo "$((diff / day))d"
    elif [ "$diff" -lt "$((day * 365))" ]; then
        echo "$((diff / (day * 30)))mo"
    else
        echo "$((diff / (day * 365)))y"
    fi
}

# Escape a string for use inside a double-quoted `bash -c` snippet
shell_escape() {
    local value="$1"
    value="${value//\\/\\\\}"
    echo "${value//\"/\\\"}"
}

# Build a single CSV row for one repository
build_row() {
    local repo_path="$1"
    cd "$repo_path" || return

    local repo_name=$(basename "$repo_path")
    local branch=$(get_branch)

    # Color code main branches
    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
        branch=$(gum style --foreground "$GREEN" "$branch")
    elif [[ "$branch" != "N/A" ]]; then
        branch=$(gum style --foreground "$YELLOW" "$branch")
    fi

    # Get changes (returns modified:staged:untracked)
    IFS=':' read -r modified staged untracked <<< "$(get_changes)"

    # Get remote status and domain (returns status:domain)
    IFS=':' read -r remote_status remote_domain <<< "$(get_remote_status)"

    # Overall status with color
    local status
    if [ "$modified" -gt 0 ] || [ "$staged" -gt 0 ] || [ "$untracked" -gt 0 ]; then
        status="$(gum style --foreground "$ORANGE" "⚠ Changes")"
    else
        status="$(gum style --foreground "$GREEN" "✓ Clean")"
    fi

    # Format changes with emojis and colors
    local changes_str=""
    if [ "$modified" -gt 0 ]; then
        changes_str+="$(gum style --foreground "$ORANGE" "📝$modified")"
    fi
    if [ "$staged" -gt 0 ]; then
        [ -n "$changes_str" ] && changes_str+=" "
        changes_str+="$(gum style --foreground "$GREEN" "✓$staged")"
    fi
    if [ "$untracked" -gt 0 ]; then
        [ -n "$changes_str" ] && changes_str+=" "
        changes_str+="$(gum style --foreground "$GRAY" "❓$untracked")"
    fi
    [ -z "$changes_str" ] && changes_str="$(gum style --foreground "$GREEN" "-")"

    # Color remote status
    if [[ "$remote_status" == "⚠ No remote" ]]; then
        remote_status="$(gum style --foreground "$YELLOW" "$remote_status")"
    elif [[ "$remote_status" == "✓ Sync" ]]; then
        remote_status="$(gum style --foreground "$GREEN" "$remote_status")"
    elif [[ "$remote_status" =~ ^↓ ]]; then
        remote_status="$(gum style --foreground "$ORANGE" "$remote_status")"
    elif [[ "$remote_status" =~ ^↑ ]]; then
        remote_status="$(gum style --foreground "$BLUE" "$remote_status")"
    elif [[ "$remote_status" =~ ^↕ ]]; then
        remote_status="$(gum style --foreground "$RED" "$remote_status")"
    fi

    # Color domain based on public/private SCM
    if [[ "$remote_domain" =~ github\.com|gitlab\.com|bitbucket\.org ]]; then
        remote_domain="$(gum style --foreground "$BLUE" "🌐 $remote_domain")"
    elif [[ "$remote_domain" != "-" ]]; then
        remote_domain="$(gum style --foreground "$GRAY" "🔒 $remote_domain")"
    fi

    local last_commit=$(get_last_commit)

    # Last modification epoch and its human-readable equivalent
    local last_modified=$(get_last_modified)
    local age=$(format_age "$last_modified")

    # Internal record uses FS_CHAR: epoch first so the records can be sorted
    # numerically, then the display fields. Only the commit message can
    # contain commas, so it is the only field that needs CSV escaping.
    printf '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n' \
        "$last_modified" "$FS_CHAR" \
        "$(field_escape "$repo_name")" "$FS_CHAR" \
        "$(field_escape "$branch")" "$FS_CHAR" \
        "$(field_escape "$status")" "$FS_CHAR" \
        "$(field_escape "$changes_str")" "$FS_CHAR" \
        "$(field_escape "$remote_status")" "$FS_CHAR" \
        "$(field_escape "$remote_domain")" "$FS_CHAR" \
        "$age" "$FS_CHAR" \
        "$(csv_escape "$last_commit")"
}

# Main
main() {
    local scan_dir="${1:-.}"

    check_gum

    # Resolve the directory to scan to an absolute path
    scan_dir="$(cd "$scan_dir" 2>/dev/null && pwd)" || {
        echo "❌ Directory not found: ${1:-.}"
        exit 1
    }

    # Banner
    gum style \
        --foreground "$BLUE" \
        --border double \
        --border-foreground "$BLUE" \
        --align center \
        --width 80 \
        --margin "1 0" \
        --padding "1 2" \
        "🔍 Git Repository Status Scanner" \
        "Scanning: $scan_dir"

    # Temporary files: raw records and final CSV fed to `gum table`
    TEMP_RECORDS=$(mktemp)
    TEMP_CSV=$(mktemp)
    trap cleanup EXIT

    # Collect repository paths (cheap, no git calls) then inspect each one.
    # The spinner only wraps the fast find phase so it can never swallow output.
    REPOS_FILE=$(mktemp)
    local vendor_prune
    vendor_prune="$(build_vendor_prune)"
    # Matches both regular repositories (.git is a directory) and linked
    # worktrees (.git is a file pointing at the main repo's gitdir).
    gum spin --spinner dot --title "Scanning repositories..." -- \
        bash -c "find \"$(shell_escape "$scan_dir")\" \( -type d \( $vendor_prune \) -prune \) -o \( -name .git -prune -print \) 2>/dev/null | while read -r g; do d=\$(dirname \"\$g\"); (cd \"\$d\" && pwd); done | sort > \"$(shell_escape "$REPOS_FILE")\""

    # Build one record per repository (separator 0x1f is never a CSV comma)
    while IFS= read -r repo_path; do
        [ -z "$repo_path" ] && continue
        build_row "$repo_path" >> "$TEMP_RECORDS"
    done < "$REPOS_FILE"
    rm -f "$REPOS_FILE"
    REPOS_FILE=""

    local repo_count=$(wc -l < "$TEMP_RECORDS")

    if [ "$repo_count" -eq 0 ]; then
        gum style \
            --foreground "$YELLOW" \
            --bold \
            "⚠️  No Git repositories found in: $scan_dir"
        exit 0
    fi

    # Newest first: the first field of every record is the epoch of the last
    # commit. Sorting happens on the raw records (before the ANSI colours and
    # the CSV quoting are applied) so ordering is numeric and reliable.
    sort -t"$FS_CHAR" -k1,1nr -k2,2 "$TEMP_RECORDS" -o "$TEMP_RECORDS"

    # Convert records into CSV: commas survive because only the commit
    # message can contain them and it is quoted on demand.
    while IFS="$FS_CHAR" read -r epoch c1 c2 c3 c4 c5 c6 age c7; do
        printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
            "$c1" "$c2" "$c3" "$c4" "$c5" "$c6" "$age" "$c7" >> "$TEMP_CSV"
    done < "$TEMP_RECORDS"

    # Show statistics
    gum style \
        --foreground "$GREEN" \
        --bold \
        --margin "1 0 0 0" \
        "📊 Found $repo_count repositories" \
        "🕒 Sorted by last commit (newest first)"

    # Display table with gum
    echo ""
    gum table \
        --separator "," \
        --columns "Repository,Branch,Status,Changes,Remote,Domain,Age,Last Commit" \
        --border rounded \
        --border.foreground "$BLUE" \
        --widths 24,14,12,13,14,18,6,34 \
        --print < "$TEMP_CSV" || true

    # Summary of states
    echo ""
    local clean_count=$(grep -c "✓ Clean" "$TEMP_CSV")
    local dirty_count=$(grep -c "⚠ Changes" "$TEMP_CSV")
    local no_remote=$(grep -c "No remote" "$TEMP_CSV")

    SUMMARY=$(gum style --foreground "$GREEN" "✓ Clean: $clean_count")
    SUMMARY="$SUMMARY  "
    SUMMARY="$SUMMARY$(gum style --foreground "$ORANGE" "⚠ With changes: $dirty_count")"
    SUMMARY="$SUMMARY  "
    SUMMARY="$SUMMARY$(gum style --foreground "$YELLOW" "⚠ No remote: $no_remote")"

    echo "$SUMMARY"
    echo ""
}

# Execute
main "$@"
