#!/usr/bin/env bash

function install_zsh()
{
    if [[ ${SHELL} != *"zsh"* ]]; then
        if ! command -v zsh > /dev/null 2>&1; then
            install zsh
            sh -c "$(wget -O- https://install.ohmyz.sh/)"
        fi

        rm ~/.zshrc; ln -s ${CONFIG_PATH}/.zshrc ~/.zshrc

        ZSH_C="${HOME}/.oh-my-zsh/custom"
        OMZsh_C_P="${ZSH_C}/plugins/"

        cd "${OMZsh_C_P}"
        [[ ! -d ${OMZsh_C_P}/zsh-autosuggestions ]] && git clone https://github.com/zsh-users/zsh-autosuggestions
        [[ ! -d ${OMZsh_C_P}/zsh-completions ]] && git clone https://github.com/zsh-users/zsh-completions
        [[ ! -d ${OMZsh_C_P}/zsh-navigation-tools ]] && git clone https://github.com/z-shell/zsh-navigation-tools
        [[ ! -d ${OMZsh_C_P}/zsh-syntax-highlighting ]] && git clone https://github.com/zsh-users/zsh-syntax-highlighting
        [[ ! -d ${OMZsh_C_P}/zsh-history-substring-search ]] && git clone https://github.com/zsh-users/zsh-history-substring-search
        [[ ! -d ${OMZsh_C_P}/alias-tips ]] && git clone https://github.com/djui/alias-tips.git
        [[ ! -d ${OMZsh_C_P}/zsh-256color ]] && git clone https://github.com/chrissicool/zsh-256color
        [[ ! -d ${OMZsh_C_P}/zsh-terraform ]] && git clone https://github.com/ptavares/zsh-terraform
        [[ ! -d ${OMZsh_C_P}/azcli ]] && git clone https://github.com/dmakeienko/azcli.git
        [[ ! -d ${OMZsh_C_P}/jq ]] && git clone https://github.com/reegnz/jq-zsh-plugin ./jq
        [[ ! -d ${OMZsh_C_P}/zsh-z ]] && git clone https://github.com/agkozak/zsh-z
        cd -

        install autojump

        OMZsh_C_T="${ZSH_C}/themes/"
        if ! [[ -L "${OMZsh_C_T}" ]]; then
            [[ -d "${OMZsh_C_T}" ]] && rm -rf "${OMZsh_C_T}"
            mkdir -p "$(dirname "${OMZsh_C_T}")"
            ln -s "${CONFIG_PATH}/.oh-my-zsh/custom/themes/" "${OMZsh_C_T}"
        fi
        cd -
    fi
}

function install_fonts()
{
    install_font_nerdfonts
    install_powerlevel10k
}

function install_powerlevel10k()
{
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
}

function install_font_nerdfonts()
{
    install fontconfig

    set -e
    cd /tmp
    git clone --filter=blob:none --sparse git@github.com:ryanoasis/nerd-fonts.git
    cd nerd-fonts
    fonts=(
        "DroidSansMono"
        "FiraCode"
        "Hack"
    )
    for f in "${fonts[@]}"; do
        git sparse-checkout add patched-fonts/${f}
        ./install.sh ${f}
        ./font-patcher --complete
    done

    cd ..
    rm -rf nerd-fonts
    set +e

    docker run -v ~/.local/share/fonts/:/in -v ~/.local/share/fonts/:/out nerdfonts/patcher --powerline --powerlineextra
    sudo chown -R $USER:$USER ~/.local/share/fonts

    fc-cache -fv
}

function install_pyenv()
{
    sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl \
    libncursesw5-dev xz-utils libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    curl https://pyenv.run | bash
}
