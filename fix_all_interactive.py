#!/usr/bin/env python3
"""Fix all interactive installations across configLinux bootstrap scripts."""

files_to_fix = {
    '/home/svg153/configLinux/SCRIPTS/bootstrap/linux-devtools.sh': [
        # line 14: 'update' should be 'sudo apt update'
        ('sudo apt install -y gum\n    update\n    install gum',
         'sudo apt install -y gum'),
        # line 70: 'install curl' call - should use 'install_by_pgkmanager curl' instead
        ('[[ -x "$(command -v curl)" ]] || install curl',
         '[[ -x "$(command -v curl)" ]] || install_by_pgkmanager curl'),
        # line 71: 'curl https://webi.sh/webi | sh' should have -y
        ('curl https://webi.sh/webi | sh',
         'curl https://webi.sh/webi | sh -y'),
        # line 97-100: install_python() function has 'install \\' which should become 'install_by_pgkmanager'
        # Actually 'install' IS defined in linux-core.sh - so these calls to 'install' and 'install_by_pgkmanager' work there.
        # The problem is when linux-devtools.sh is sourced standalone, 'install()' isn't defined.
        # Let's keep 'install curl' but fix the actual 'install()' calls that might be problematic.
    ],
    '/home/svg153/configLinux/SCRIPTS/bootstrap/linux-github.sh': [
        # npm install -g commands  
        ('sudo npm install -g npm',
         'sudo npm install -y npm'),
        ('sudo npm install -g @githubnext/github-copilot-cli',
         'npm install -y -g @githubnext/github-copilot-cli'),
    ],
    '/home/svg153/configLinux/SCRIPTS/bootstrap/linux-ai.sh': [
        # npx skills - need to replace with proper cloning mechanism
        ("npx skills https://github.com/${skill} --global --yes",
         "npx skills ${skill} --global --yes"),
    ],
    '/home/svg153/configLinux/SCRIPTS/bootstrap/linux-cloud.sh': [
        ('curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh | bash',
         'curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh | bash -y'),
        ('pipx install checkov',
         'pipx install --global checkov'),
        ('curl -sSfL https://raw.githubusercontent.com/busser/tfautomv/main/install.sh | sudo sh',
         'curl -sSfL https://raw.githubusercontent.com/busser/tfautomv/main/install.sh | sudo sh -y'),
    ],
}

for filepath, replacements in files_to_fix.items():
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        for old, new in replacements:
            if old in content:
                content = content.replace(old, new)
                print(f"  ✓ Fixed in {filepath.split('/')[-1]}")
            else:
                print(f"  ✗ Pattern not found: {old[:50]}...")
        
        with open(filepath, 'w') as f:
            f.write(content)
    except Exception as e:
        print(f"  ✗ Error processing {filepath}: {e}")

print("\n✅ Done!")