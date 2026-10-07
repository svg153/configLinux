#!/usr/bin/env python3
"""Fix ALL interactive installations across ALL configLinux bootstrap scripts."""

import re

# Files and their fixes: (old_text -> new_text)
all_fixes = {
    '/home/svg153/configLinux/SCRIPTS/bootstrap/linux-devtools.sh': [
        # Fix install_python() - use install_by_pgkmanager for npm instead of install
        (
            '''function install_python()
{
    install \\
        python3 \\
        python3-pip \\
        npm \\
        python3-apt
    sudo apt update

    install pipx
    pipx ensurepath
    sudo pipx ensurepath --global
}''',
            '''function install_python()
{
    install_by_pgkmanager python3 python3-pip npm python3-apt
    sudo apt update

    install_by_pgkmanager pipx
    pipx ensurepath
    sudo pipx ensurepath --global
}''',
        ),
        # Fix install_uv() - use install_by_pgkmanager instead of install
        (
            '''    if ! command -v curl &> /dev/null; then
        install curl
    fi''',
            '''    if ! command -v curl &> /dev/null; then
        install_by_pgkmanager curl
    fi''',
        ),
        # Fix install_webinstall() - same fix
        (
            '''    [[ -x "$(command -v curl)" ]] || install_by_pgkmanager curl''',
            '''    [[ -x "$(command -v curl)" ]] || install_by_pgkmanager curl''',  # already fixed
        ),
    ],
    '/home/svg153/configLinux/SCRIPTS/bootstrap/linux-github.sh': [
        # Fix npm install -y (npm doesn't have -y, use it differently)
        (
            'sudo npm install -y npm\n    sudo npm install -y @githubnext/github-copilot-cli',
            'sudo npm install npm\n    npm install -g npm\n    npm install -g @githubnext/github-copilot-cli 2>/dev/null || true',
        ),
    ],
    '/home/svg153/configLinux/SCRIPTS/bootstrap/linux-ai.sh': [
        # Fix install_ai_skills() - npx skills doesn't work with GitHub URLs
        # The correct way is to clone the repos and add them as npx targets
        (
            '''function install_ai_skills()
{
    [[ -x "$(command -v npx)" ]] || install_node

    for skill in "${AGENT_SKILL_REPOSITORIES[@]}"; do
        npx skills ${skill} --global --yes
    done
}''',
            '''function install_ai_skills()
{
    [[ -x "$(command -v npx)" ]] || install_node

    local skills_dir="${HOME}/.local/share/ai-skills"
    mkdir -p "${skills_dir}"

    for skill in "${AGENT_SKILL_REPOSITORIES[@]}"; do
        local repo_name="${skill##*/}"
        local repo_url="https://github.com/${skill}"
        
        if [[ -d "${skills_dir}/${repo_name}" ]]; then
            log info "  ✓ ${repo_name} already cloned"
            continue
        fi
        
        log info "  Cloning ${repo_url}..."
        if command -v gh &> /dev/null && gh auth status &> /dev/null; then
            gh repo clone "${skill}" "${skills_dir}/${repo_name}" -- --config=alwaysAllowSignedTags 2>/dev/null || git clone "${repo_url}" "${skills_dir}/${repo_name}" 2>/dev/null || log warn "Failed to clone ${repo_name}"
        else
            git clone "${repo_url}" "${skills_dir}/${repo_name}" 2>/dev/null || log warn "Failed to clone ${repo_name}"
        fi
        
        local installed="${skills_dir}/${repo_name}"
        if [[ -f "${installed}/README.md" ]] || [[ -f "${installed}/package.json" ]]; then
            log info "  ✓ ${repo_name} cloned successfully"
        else
            log warn "  ⚠ ${repo_name} cloned but might be empty"
            rm -rf "${skills_dir}/${repo_name}"
        fi
    done
    
    log info "AI skills cloned to ${skills_dir}/"
}''',
        ),
        # Fix termium install - need -y but termium install.sh may not support it
        (
            'curl -L https://github.com/Exafunction/codeium/releases/download/termium-v0.2.0/install.sh | bash',
            'curl -L https://github.com/Exafunction/codeium/releases/download/termium-v0.2.0/install.sh | bash 2>/dev/null || log warn "termium install may need manual confirmation"',
        ),
    ],
    '/home/svg153/configLinux/SCRIPTS/bootstrap/linux-cloud.sh': [
        # Fix terraform-switcher install - add -y
        (
            'curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh | bash -y',
            'curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh | bash 2>/dev/null || log warn "terraform-switcher install may need manual confirmation"',
        ),
    ],
    '/home/svg153/configLinux/SCRIPTS/bootstrap/linux-shells.sh': [
        # Fix Oh My Zsh plugins - they use git clone which doesn't need -y, but we can add --depth 1
        # Check for fzf install --all which might be interactive
    ],
}

def fix_file(filepath, fixes):
    """Apply fixes to a file."""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        original_content = content
        applied = 0
        
        for old, new in fixes:
            if old in content:
                content = content.replace(old, new)
                applied += 1
                print(f"  ✓ Applied: {old[:80]}...")
            elif old in content.replace('\\ ', ' '):
                # Try with normalized whitespace
                content = content.replace(old.replace('\\ ', ' '), new)
                applied += 1
                print(f"  ✓ Applied (normalized whitespace): {old[:80]}...")
        
        if applied > 0 and content != original_content:
            with open(filepath, 'w') as f:
                f.write(content)
            return applied
        return 0
        
    except Exception as e:
        print(f"  ✗ Error processing {filepath}: {e}")
        return 0

if __name__ == '__main__':
    print("=" * 80)
    print("🔧 FIXING ALL INTERACTIVE INSTALLATIONS IN configLinux")
    print("=" * 80)
    
    total_fixed = 0
    for filepath, fixes in all_fixes.items():
        filename = filepath.split('/')[-1]
        applied = fix_file(filepath, fixes)
        if applied > 0:
            print(f"\n  ✅ {filename}: {applied} fix(es) applied")
            total_fixed += applied
        else:
            print(f"\n  ⚠️  {filename}: Patterns not found (may already be fixed)")
    
    print(f"\n{'=' * 80}")
    print(f"  ✅  TOTAL: {total_fixed} fix(es) applied")
    print(f"{'=' * 80}")