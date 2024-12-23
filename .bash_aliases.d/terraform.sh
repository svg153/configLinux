#!/bin/bash

terraform_get_provider_full_name() {
  local provider_name="$1"

  if [[ $# -ne 1 ]]; then
    echo "Usage: terraform_get_provider_full_name <provider_name>"
    return 1
  fi

  local -r provider_full_name="terraform-provider-${provider_name}"
  echo "${provider_full_name}"
}

terraform_provider_get_latest_version() {
  local provider_name="$1"

  if [[ $# -ne 1 ]]; then
    echo "Usage: terraform_provider_get_latest_version <provider_name>"
    return 1
  fi

  local -r provider_full_name="$(terraform_get_provider_full_name "${provider_name}")"
  provider_version="$(curl -s "https://releases.hashicorp.com/${provider_full_name}/index.json" | jq -r '.versions[].version' | sort -V | tail -n 1)"
  
  echo "${provider_version}"
}

terraform_provider_install() {
  local provider_name=$1
  local provider_version=$2

  if [[ $# -eq 1 ]]; then
    provider_version="$(terraform_provider_get_latest_version "${provider_name}")"
  elif [[ $# -eq 2 ]]; then
    provider_version="$2"
  else
    echo "Usage: terraform_provider_install <provider_name> [<provider_version>]"
    return 1
  fi

  local -r zip="terraform-provider-${provider_name}_${provider_version}_linux_amd64.zip"
  local -r provider_full_name="$(terraform_get_provider_full_name "${provider_name}")"
  local -r url="https://releases.hashicorp.com/${provider_full_name}/${provider_version}/${zip}"
  local -r bin="${provider_full_name}_v${provider_version}_x5"
  local -r bin_path_destiny="${HOME}/.terraform.d/plugins/linux_amd64/"

  wget "${url}" \
    && unzip "${zip}" && rm "${zip}" \
    && mv "${bin}" "${bin_path_destiny}"
}

terraform_provider_azurerm_install() {
  local -r provider_name="azurerm"
  local -r provider_version=$(terraform_provider_get_latest_version "${provider_name}")

  terraform_provider_install "${provider_name}" "${provider_version}"
}

terraform_apply_targets() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: terraform_apply_targets [--auto-approve] <target1> [<target2> ...] "
    return 1
  fi

  local auto_approve=""
  if [[ "$1" == "--auto-approve" ]]; then
    auto_approve="--auto-approve"
    shift
  fi

  local -r targets=("$@")
  local -r targets_str=$(IFS=","; echo "${targets[*]}" | sed 's/,/ --target=/g')

  echo terraform apply ${auto_approve} --target="${targets_str}"
}

tf_summarize() {
  docker run -v $PWD:/workspace -w /workspace ghcr.io/dineshba/tf-summarize $@
}

tfsec() {
  docker run -v $PWD:/workspace -w /workspace ghcr.io/dineshba/tfsec $@
}

tfnotify() {
  docker run -v $PWD:/workspace -w /workspace ghcr.io/dineshba/tfnotify $@
}

### Tools

# tfautomove installed use tfautomv

alias tfaat="terraform_apply_targets --auto-approve"
alias tfat="terraform_apply_targets"

alias tf-summarize="tf_summarize"

alias tfnotify-plan="tfnotify plan"