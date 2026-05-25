#!/usr/bin/env bash

function detect_wsl_environment()
{
    if uname -a | grep -qi 'WSL'; then
        echo "true"
    else
        echo "false"
    fi
}

function require_configlinux_env_paths()
{
    if [[ -z "${PROGRAMAS_PATH:-}" ]] || [[ -z "${REPOS_PATH:-}" ]] || [[ -z "${WORK_REPOS_PATH:-}" ]] || [[ -z "${PERSONAL_REPOS_PATH:-}" ]] || [[ -z "${CONFIG_PATH:-}" ]]; then
        echo "Some variables are empty"
        return 1
    fi
}

function aptt() {
    sudo apt -qq -y "$@"
}

function install_by_apt() {
    aptt install "$@"
}

function install_by_yum() {
   sudo yum -y install "$@"
}

function install_by_pgkmanager() {
    if [[ -x "$(command -v apt-get)" ]]; then
        install_by_apt "$@"
    elif [[ -x "$(command -v yum)" ]]; then
        install_by_yum "$@"
    else
        echo "Package manager not found"
        return 1
    fi
}

function get_os_distribution() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$NAME"
  elif type lsb_release >/dev/null 2>&1; then
    echo "$(lsb_release -si)"
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    echo "$DISTRIB_ID"
  elif [ -f /etc/debian_version ]; then
    echo Debian
  elif [ -f /etc/SuSe-release ]; then
    echo SuSe
  elif [ -f /etc/redhat-release ]; then
    echo RedHat
  else
    echo "Unknown"
  fi
}

function install() {
    install_by_pgkmanager "$@"
}

function remove() {
    aptt remove "$@"
}

function update() {
    aptt update "$@"
}

function check_if_program_is_installed() {
    local p=$1
    [[ $# -ne 1 ]] && echo "Usage: check_if_program_is_installed <program>" && return 1
    [[ -z "${p}" ]] && echo "check_if_program_is_installed: program is empty" && return 1
    [[ -x "$(command -v "${p}")" ]] && return 0
    return 1
}

function check_if_program_is_installed_in_windows() {
    local p=$1
    [[ $# -ne 1 ]] && echo "Usage: check_if_program_is_installed_in_windows <program>" && return 1
    [[ -z "${p}" ]] && echo "check_if_program_is_installed_in_windows: program is empty" && return 1
    powershell.exe -Command "Get-Command -Name ${p} -ErrorAction SilentlyContinue" > /dev/null
}

function system_update_upgrade()
{
    if [[ -x "$(command -v apt-get)" ]]; then
        sudo apt-get update \
        && sudo apt-get upgrade \
        && sudo apt-get dist-upgrade \
        && sudo apt-get autoremove
    elif [[ -x "$(command -v dnf)" ]]; then
        sudo dnf update \
        && sudo dnf upgrade
    elif [[ -x "$(command -v yum)" ]]; then
        sudo yum update \
        && sudo yum upgrade
    elif [[ -x "$(command -v pacman)" ]]; then
        sudo pacman -Syu
    elif [[ -x "$(command -v zypper)" ]]; then
        sudo zypper update \
        && sudo zypper upgrade
    else
        echo "No package manager found"
    fi
}