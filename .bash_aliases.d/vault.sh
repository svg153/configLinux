#!/bin/bash

export VAULT_ADDR=''

# LDAP login
alias vlg="vault login -method=ldap username=$USER"

# Vault secret as base64-encoded strings
vault_kv_get_base64() {
  local secret_path="$1"
  vault kv get -format=json "$secret_path" \
    | jq -r '.data.data | to_entries[] | "\(.key): \(.value|tostring|@base64)"'
}

# Interactive kv secret navigation with fzf
vkf() {
  # List all kv secret engines
  local mount
  mount=$(vault secrets list -format=json | jq -r 'to_entries[] | select(.value.type=="kv") | .key' | fzf --prompt="Select kv mount: ")
  [ -z "$mount" ] && return 1

  # List keys
  local path=""
  while true; do
    local keys
    keys=$(vault kv list -format=json "${mount}${path}" 2>/dev/null | jq -r '.[]')
    [ -z "$keys" ] && break
    local selected
    selected=$(echo "$keys" | fzf --prompt="Select key or folder: ")
    [ -z "$selected" ] && break
    if [[ "$selected" == */ ]]; then
      path="${path}${selected}"
    else
      vault_kv_get_base64 "${mount}${path}${selected}"
      break
    fi
  done
}

# Interactive fzf policy navigation
vpf() {
  local policy
  policy=$(vault policy list | fzf --prompt="Select policy: ")
  [ -n "$policy" ] && vault policy read "$policy"
}
