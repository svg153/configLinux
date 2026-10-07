#!/usr/bin/env python3
import re

file_path = '/home/svg153/configLinux/SCRIPTS/bootstrap/linux-devtools.sh'

with open(file_path, 'r') as f:
    content = f.read()

# 1. Fix install_python() - remove distutils, add npm
content = re.sub(
    r'(def install_python\(\).*?pip3 install -q (?:--break-system-packages -q )\?(\w+)distutils\s*)',
    r'\1\n    pip3 install -q --break-system-packages npm',
    content
)

# 2. Fix install_gotask - add -y
content = re.sub(
    r'(sh -c "\$\(.+taskfile\.dev/install\.sh\)" -- -d -b)',
    r'\1 -y',
    content
)

# 3. Fix install_d2lang - add -y
content = re.sub(
    r'(curl -fsSL https://d2lang\.com/install\.sh \| sh -s --)\s*$',
    r'\1 -y',
    content,
    flags=re.MULTILINE
)

# 4. Fix install_starship - add -y
content = re.sub(
    r'(curl -fsSL https://starship\.rs/install\.sh) -b /usr/local/bin',
    r'\1 -y -b /usr/local/bin',
    content
)

# 5. Fix install_uv - add -y
content = re.sub(
    r'(curl -LsSf https://astral\.sh/uv/install\.sh) \| sh\s*$',
    r'\1 | sh -y',
    content,
    flags=re.MULTILINE
)

with open(file_path, 'w') as f:
    f.write(content)

print("✅ All fixes applied successfully!")