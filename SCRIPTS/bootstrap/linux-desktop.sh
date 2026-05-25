#!/usr/bin/env bash

function install_chrome()
{
    if [[ -x "$(command -v google-chrome)" ]]; then
        google-chrome --version
        return 0
    fi

    local deb_filename="google-chrome-stable_current_amd64.deb"
    local deb_filepath_dw="${PROGRAMAS_PATH}/${deb_filename}"
    wget -O ${deb_filepath_dw} https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb ${PROGRAMAS_PATH}
    sudo dpkg -i ${deb_filepath_dw}
    sudo apt-get --fix-broken-install && sudo apt-get update && install && rm ${deb_filepath_dw}
}

function install_vscode()
{
    if [[ -x "$(command -v code)" ]]; then
        code --version
        return 0
    fi

    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    update
    install code
}

function install_telegram()
{
    if [[ -x "$(command -v telegram)" ]]; then
        telegram --version
        return 0
    fi

    wget -O ${PROGRAMAS_PATH}/tsetup.tar.xz https://telegram.org/dl/desktop/linux
    cd ${PROGRAMAS_PATH}
    tar xvf tsetup.tar.xz
    sudo ln -s ${PROGRAMAS_PATH}/Telegram/Telegram ~/bin/telegram
    rm -rf tsetup.tar.xz
    cd -
}
