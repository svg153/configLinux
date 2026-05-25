#!/usr/bin/env bash

function print_doctor_report()
{
    log info "configLinux doctor"
    echo "mode=${MODE}"
    echo "script_dir=${SCRIPT_DIR}"
    echo "config_path=${CONFIG_PATH}"
    echo "repo_path_exists=$([[ -d "${CONFIG_PATH}" ]] && echo true || echo false)"
    echo "is_wsl=${isWSL}"

    local commands=(git gh node npm python3 pwsh powershell.exe docker code)
    for cmd in "${commands[@]}"; do
        if command -v "${cmd}" >/dev/null 2>&1; then
            echo "cmd:${cmd}=present"
        else
            echo "cmd:${cmd}=missing"
        fi
    done

    local paths=(
        "${CONFIG_PATH}/.gitconfig"
        "${CONFIG_PATH}/.gitconfig.d/default.gitconfig"
        "${CONFIG_PATH}/templates/git/gitconfig.d/personal-mail.gitconfig"
        "${CONFIG_PATH}/templates/git/gitconfig.d/work/work.gitconfig"
        "${CONFIG_PATH}/templates/powershell/profile.ps1"
        "${CONFIG_PATH}/templates/powershell/Copilot.DevProfile.ps1"
        "${CONFIG_PATH}/templates/vscode/mcp.jsonc"
        "${CONFIG_PATH}/templates/vscode/prompts/code.instructions.md"
        "${CONFIG_PATH}/templates/windows/terminal/settings.json"
        "$HOME/.configLinux"
        "$HOME/.gitconfig"
        "$HOME/.gitconfig.d"
        "$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"
        "$HOME/.config/Code - Insiders/User/mcp.json"
        "$HOME/.config/Code - Insiders/User/prompts/code.instructions.md"
    )

    for p in "${paths[@]}"; do
        if [[ -e "${p}" ]]; then
            echo "path:${p}=present"
        else
            echo "path:${p}=missing"
        fi
    done
}

function run_linux_stage_base()
{
    system_update_upgrade

    if [[ ${isWSL} == "true" ]]; then
        log info "Skipping driver install for WSL"
    else
        install_drivers
    fi

    install bash-completion
    install_bash_tools
    install_git
    install curl vim
    install zip unzip xclip
    install unrar || true

    if [[ ${isWSL} == "true" ]]; then
        log info "Skipping Linux desktop helper packages for WSL"
    else
        install wmctrl xdotool
    fi

    make_folder_structure
    configure_shared_base
}

function run_linux_stage_shells()
{
    log info "zsh and .oh-my-zsh"
    install_zsh
}

function run_linux_stage_devtools()
{
    log info "languages"
    install_language_toolchain_bundle

    log info "github tools"
    install_gh
    install_gh_extensions
    install_github_tools

    log info "cli tools"
    install_cli_tooling_bundle

    log info "azure"
    install_cloud_tooling_bundle

    log info "terraform"
    install_iac_tooling_bundle

    pipx install pre-commit ansible-lint black

    local tools_by_github=(
        wtfutil/wtf
        noahgorstein/jqp
        go-task/task
        altsem/gitu
    )
    for p in "${tools_by_github[@]}"; do
        install_by_gh "${p}"
    done
}

function run_linux_stage_containers()
{
    log info "docker"
    install_container_tooling_bundle
}

function run_linux_stage_desktop()
{
    log info "git GUI"
    if [[ ${isWSL} == "true" ]]; then
        log info "Skipping git-gui and gitk for WSL"
    else
        install git-gui gitk meld
    fi

    log info "openvpn"
    if [[ ${isWSL} == "true" ]]; then
        log info "Skipping openvpn for WSL"
    else
        install openvpm resolvconf network-manager-openvpn-gnome
    fi

    if [[ ${isWSL} == "true" ]]; then
        log info "Skipping chrome for WSL; installing wslu instead"
        install wslu
    fi

    if [[ ${isWSL} == "true" ]]; then
        log info "Skipping telegram for WSL"
    else
        install_telegram
    fi

    if [[ ${isWSL} == "true" ]]; then
        log info "Skipping VS Code install for WSL"
    else
        install_vscode
    fi

    if [[ ${isWSL} == "true" ]]; then
        log info "Skipping desktop app install for WSL"
    else
        install \
            xfce4-whiskermenu-plugin \
            menulibre \
            xfce4-clipman \
            xfce4-power-manager \
            xfce4-screenshooter \
            xfce4-panel-dev \
            xfce4-taskmanager \
            xfce4-terminal \
            xfce4-xkb-plugin

        install rsync vlc gimp gparted gnome-disk-utility
        install flameshot
        if [[ -L ~/${CONFIG_PATH} ]]; then
            echo "${CONFIG_PATH} is a symlink"
        else
            flameshot_configfile=.config/flameshot/flameshot.ini
            rm ${flameshot_configfile}
            ln -s ${CONFIG_PATH}/../${flameshot_configfile} ~/${flameshot_configfile}
        fi
    fi
}

function run_linux_stage_customization()
{
    if [[ ${isWSL} == "true" ]]; then
        log info "Skipping Linux desktop customization for WSL"
        return 0
    fi

    echo '[SeatDefaults]' >> /usr/share/lightdm/lightdm.conf.d/01_my.conf
    echo 'greeter-hide-users=false' >> /usr/share/lightdm/lightdm.conf.d/01_my.conf

    sudo add-apt-repository ppa:numix/ppa
    sudo apt update
    sudo apt install numix-*

    sudo cp -r ./themes/* /usr/share/themes/

    os_xfce4="~/.config/xfce4"
    os_xfconf="${os_xfce4}/xfconf"
    repo_xfce4="${CONFIG_PATH}/.config/xfce4"
    repo_xfconf="${repo_xfce4}/xfconf"

    mv ${os_xfce4}{,.ori}
    ln -s ${repo_xfce4} ${os_xfce4}

    xfce_mode="${MODE_DESKTOP}"
    [[ "${MODE}" == "${MODE_LAPTOP}" ]] && xfce_mode="${MODE_LAPTOP}"
    ln -s ${repo_xfconf}/xfce-perchannel-xml/{xfce4-power-manager-${xfce_mode}.xml,xfce4-power-manager.xml}

    keyboard_filepath_ori="/etc/default/keyboard"
    keyboard_filepath_mine="${CONFIG_PATH}/${keyboard_filepath_ori}"
    sudo cp ${keyboard_filepath_ori} ${keyboard_filepath_ori}.OLD
    sudo rm ${keyboard_filepath_ori}
    if [[ -e "${keyboard_filepath_mine}" ]]; then
        sudo ln -s ${keyboard_filepath_mine} ${keyboard_filepath_ori}
        if [[ $? -ne 0 ]]; then
            sudo cp ${keyboard_filepath_mine} ${keyboard_filepath_ori}
        fi
    fi
    sudo dpkg-reconfigure -phigh console-setup
}

function run_linux_stage_ai()
{
    bootstrap_agent_stack_linux
}

function run_linux_stage_cleanup()
{
    clone_common_repos
    sudo apt autoremove
    sudo apt clean
}

function run_linux_full_bootstrap()
{
    run_linux_stage_base
    run_linux_stage_shells
    run_linux_stage_devtools
    run_linux_stage_containers
    run_linux_stage_desktop
    run_linux_stage_customization
    run_linux_stage_ai
    run_linux_stage_cleanup
}