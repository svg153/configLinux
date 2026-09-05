#!/bin/bash

# Script to display Git repository status in a table format
# Dependencies: gum (https://github.com/charmbracelet/gum)

# Colors
RED=196
GREEN=46
YELLOW=226
BLUE=39
GRAY=240
ORANGE=208

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

# Get remote status (ahead/behind)
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

# Función principal
main() {
    local scan_dir="${1:-.}"
    
    check_gum
    
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
    
    # Crear archivo temporal para datos (no header needed, --columns creates it)
    local temp_file=$(mktemp)
    local temp_repos=$(mktemp)
    
    # Obtener path absoluto del directorio a escanear
    scan_dir="$(cd "$scan_dir" && pwd)"
    
    # Buscar todos los .git y guardar paths absolutos (sin entrar en repos anidados)
    gum spin --spinner dot --title "Scanning repositories..." -- bash -c '
        cd "'"$scan_dir"'" && find . -type d -name ".git" -prune 2>/dev/null | while read git_dir; do
            repo_dir=$(dirname "$git_dir")
            abs_path="'"$scan_dir"'/$repo_dir"
            abs_path=${abs_path//\/.\//\/}
            echo "$abs_path" >> "'"$temp_repos"'"
        done
    '
    
    # Process each repository found
    while IFS= read -r repo_path; do
        cd "$repo_path" || continue
        
        repo_name=$(basename "$repo_path")
        branch=$(get_branch)
        
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
        if [ "$modified" -gt 0 ] || [ "$staged" -gt 0 ] || [ "$untracked" -gt 0 ]; then
            status="$(gum style --foreground "$ORANGE" "⚠ Changes")"
        else
            status="$(gum style --foreground "$GREEN" "✓ Clean")"
        fi
        
        # Format changes with emojis and colors
        changes_str=""
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
        
        # Last commit
        last_commit=$(get_last_commit)
        
        # Write to CSV
        echo "$repo_name,$branch,$status,$changes_str,$remote_status,$remote_domain,$last_commit" >> "$temp_file"
    done < "$temp_repos"
    
    rm "$temp_repos"
    
    # Count repositories found
    local repo_count=$(wc -l < "$temp_file")
    
    if [ "$repo_count" -eq 0 ]; then
        gum style \
            --foreground "$YELLOW" \
            --bold \
            "⚠️  No Git repositories found in: $scan_dir"
        rm "$temp_file"
        exit 0
    fi
    
    # Show statistics
    gum style \
        --foreground "$GREEN" \
        --bold \
        --margin "1 0 0 0" \
        "📊 Found $repo_count repositories"
    
    # Display table with gum
    echo ""
    gum table \
        --separator "," \
        --columns "Repository,Branch,Status,Changes,Remote,Domain,Last Commit" \
        --border rounded \
        --border.foreground "$BLUE" \
        --widths 25,15,12,18,15,20,40 \
        --print < "$temp_file"
    
    # Summary of states
    echo ""
    local clean_count=$(grep -c "Clean" "$temp_file")
    local dirty_count=$(grep -c "Changes" "$temp_file")
    local no_remote=$(grep -c "No remote" "$temp_file")
    
    SUMMARY=$(gum style --foreground "$GREEN" "✓ Clean: $clean_count")
    SUMMARY="$SUMMARY  "
    SUMMARY="$SUMMARY$(gum style --foreground "$ORANGE" "⚠ With changes: $dirty_count")"
    SUMMARY="$SUMMARY  "
    SUMMARY="$SUMMARY$(gum style --foreground "$YELLOW" "⚠ No remote: $no_remote")"
    
    echo "$SUMMARY"
    echo ""
    
    # Cleanup
    rm "$temp_file"
}

# Execute
main "$@"
