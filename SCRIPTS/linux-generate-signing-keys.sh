#!/usr/bin/env bash
# Helper: generate SSH signing keys and allowed_signers for Linux
# Usage: ./linux-generate-signing-keys.sh [--dry-run]

set -eu
DRY=0
if [ "${1-}" = "--dry-run" ]; then
  DRY=1
fi

SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

gen_key() {
  local path="$1"; local comment="$2"
  if [ -f "$path" ]; then
    echo "Key $path already exists — skipping (remove it first if you want a fresh one)"
    return
  fi
  echo "Generating $path (comment: $comment)"
  if [ "$DRY" -eq 1 ]; then
    echo "dry-run: ssh-keygen -t ed25519 -a 64 -C \"$comment\" -f \"$path\" -N \"\""
  else
    ssh-keygen -t ed25519 -a 64 -C "$comment" -f "$path" -N ""
    chmod 600 "$path"
    chmod 644 "$path.pub"
  fi
}

# determine emails/UIDs for signing keys
GITHUB_EMAIL=${GITHUB_SIGN_EMAIL:-}
WORK_EMAIL=${WORK_SIGN_EMAIL:-}
if [ -z "$GITHUB_EMAIL" ]; then
  read -p "GitHub signing email (for the comment field, e.g. you@example.com): " GITHUB_EMAIL
fi
if [ -z "$WORK_EMAIL" ]; then
  read -p "Work signing email (for the comment field, e.g. you@company.com): " WORK_EMAIL
fi

gen_key "$SSH_DIR/id_ed25519_sign_github" "$GITHUB_EMAIL"
gen_key "$SSH_DIR/id_ed25519_sign_work" "$WORK_EMAIL"

allowed="$SSH_DIR/allowed_signers"
echo "Writing allowed_signers -> $allowed"
if [ "$DRY" -eq 1 ]; then
  echo "dry-run: create allowed_signers with both public keys"
else
  # By default write placeholder UIDs; user should edit allowed_signers to the UID/Github account name they will use
  printf "<GITHUB_SIGN_UID> %s\n" "$(cat $SSH_DIR/id_ed25519_sign_github.pub)" > "$allowed"
  printf "<WORK_SIGN_UID> %s\n" "$(cat $SSH_DIR/id_ed25519_sign_work.pub)" >> "$allowed"
  chmod 644 "$allowed"
  echo "Wrote $allowed with placeholder UIDs. Edit it to replace <GITHUB_SIGN_UID> and <WORK_SIGN_UID> with the actual identifiers you will register on the platforms."
fi

echo "\nGit config commands to run (or add to ~/.gitconfig):"
cat <<'EOF'
git config --global gpg.format ssh
git config --global gpg.ssh.program /usr/bin/ssh-keygen
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
git config --global commit.gpgsign true
git config --global tag.gpgSign true
EOF

echo "Done. Review the generated files in $SSH_DIR and upload the .pub signing keys to GitHub/GHES (SSH signing keys)."
