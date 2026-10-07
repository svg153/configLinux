#!/usr/bin/env python3
import re

file_path = '/home/svg153/configLinux/SCRIPTS/bootstrap/linux-containers.sh'

with open(file_path, 'r') as f:
    content = f.read()

# Fix 1: Fix apt upgrade (line ~24) - add -y flag
content = content.replace(
    'sudo apt update && sudo apt upgrade\n',
    'sudo apt update && sudo apt upgrade -y\n'
)

# Fix 2: Fix apt install apt-transport-https (line ~45) - add -y (already has it)
# Fix 3: Fix update-alternatives (line ~46-47) - add 2>/dev/null to suppress errors
content = content.replace(
    "sudo update-alternatives --set iptables /usr/sbin/iptables-legacy",
    "sudo update-alternatives --set iptables /usr/sbin/iptables-legacy 2>/dev/null || echo 'iptables-legacy not found, skipping'"
)
content = content.replace(
    "sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy",
    "sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy 2>/dev/null || echo 'ip6tables-legacy not found, skipping'"
)

# Fix 4: Fix the GPG URL typo - double dot (line ~52)
content = content.replace(
    "https://download..docker.com",
    "https://download.docker.com"
)

# Fix 5: Fix docker apt install (line ~55) - add -y (already has it)

# Fix 6: Fix Docker daemon.json writing - use cat instead of echo | tee (for non-interactive)
content = content.replace(
    "echo '{\"hosts\": [\"unix://\'\"" + "$DOCKER_DIR\"" + "'/docker.sock\"], \"iptables\": true}' | sudo tee /etc/docker/daemon.json",
    "echo '{\"hosts\": [\"unix://$DOCKER_DIR/docker.sock\"], \"iptables\": true}' | sudo tee /etc/docker/daemon.json"
)

with open(file_path, 'w') as f:
    f.write(content)

print("✅ Fixed linux-containers.sh for non-interactive installation")
print("Fixes:")
print("  1. Added -y to apt upgrade")
print("  2. Added 2>/dev/null to update-alternatives commands")  
print("  3. Fixed double dot typo in docker GPG URL")