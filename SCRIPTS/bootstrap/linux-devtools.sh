#!/usr/bin/env bash

function install_gum()
{
    if [[ -x "$(command -v gum)" ]]; then
        gum --version
        return 0
    fi

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install gum
    update
    install gum
}

function install_ijq()
{
    if [[ -x "$(command -v ijq)" ]]; then
        ijq -V
        return 0
    fi

    local version=1.1.2
    wget "https://git.sr.ht/~gpanders/ijq/refs/download/v${version}/ijq-${version}-linux-amd64.tar.gz"
    tar xf ijq-${version}-linux-amd64.tar.gz
    cd ijq-${version}
    sudo cp ijq /usr/local/bin/ijq-${version}
    sudo ln -s /usr/local/bin/ijq-${version} /usr/local/bin/ijq
    sudo mkdir -p /usr/local/share/man/man1
    sudo cp ijq.1 /usr/local/share/man/man1
    cd ..
    rm -rf ijq-${version}
    rm ijq-${version}-linux-amd64.tar.gz
}

function install_fzf()
{
    if [[ -x "$(command -v fzf)" ]]; then
        if [[ -d ~/.fzf ]]; then
            git -C ~/.fzf pull
        else
            echo "fzf is already installed, but not by repository"
        fi
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    fi
    ~/.fzf/install --all
}

function install_gotask()
{
    if [[ -x "$(command -v task)" ]]; then
        echo "task is already installed"
    else
        sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin
    fi
}

function install_taskfalcon()
{
    if [[ -x "$(command -v taskfalcon)" ]]; then
        taskfalcon --help
        return 0
    fi

    curl -L https://taskfalcon.org/bin/TaskFalcon-Linux.tgz | tar xz \
        && sudo mv falcon /usr/local/bin/falcon \
        && sudo chmod +x /usr/local/bin/falcon \
        && sudo ln -s /usr/local/bin/falcon /usr/local/bin/taskfalcon \
        && taskfalcon --help
}

function install_webinstall()
{
    if [[ -x "$(command -v webi)" ]]; then
        webi --version
        return 0
    fi

    [[ -x "$(command -v curl)" ]] || install curl
    curl https://webi.sh/webi | sh
}

function install_by_webinstall()
{
    local p=$1
    [[ $# -ne 1 ]] && echo "webinstall: webinstall <program>" && return 1
    [[ -z "${p}" ]] && echo "webinstall: program is empty" && return 1
    webi ${p}
}

function install_python()
{
    install \
        python3 \
        python3-pip \
        python3-distutils \
        python3-apt
    sudo apt update

    install pipx
    pipx ensurepath
    sudo pipx ensurepath --global
}

function install_node()
{
    if [[ -x "$(command -v node)" ]]; then
        version=$(node -v)
        echo "node is already installed, version: ${version}"
        return 0
    fi

    local os_distribution=$(get_os_distribution)

    if [[ ${os_distribution} = *"Debian"* ]] || [[ ${os_distribution} = *"Ubuntu"* ]]; then
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - \
        && sudo apt-get install -y nodejs
    elif [[ ${os_distribution} = *"CentOS"* ]] || [[ ${os_distribution} = *"Fedora"* ]]; then
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo -E bash - \
        && sudo yum install nodejs -y --skip-broken && sudo yum install nsolid -y --skip-broken
    else
        echo "OS distribution not supported"
    fi
}

function install_golang()
{
    local -r go_version="1.23.4"

    wget https://go.dev/dl/go${go_version}.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go${go_version}.linux-amd64.tar.gz
    if ! command -v go &> /dev/null; then
        echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
        source ~/.bashrc
    fi
}

function install_d2lang()
{
    curl -fsSL https://d2lang.com/install.sh | sh -s --
}

function install_starship()
{
    if [[ -x "$(command -v starship)" ]]; then
        starship --version
        return 0
    fi

    sh -c "$(curl -fsSL https://starship.rs/install.sh)"
    if [[ ! -d ~/.config ]]; then
        mkdir -p ~/.config
    fi
}

function install_language_toolchain_bundle()
{
    install_python
    install_node
    install_by_pgkmanager golang-go
    install_d2lang
}

function install_cli_tooling_bundle()
{
    install_by_pgkmanager w3m
    install_gum
    install_ijq
    install_starship
    install_fzf
    install_gotask
    install_taskfalcon
    install_webinstall

    local tools_by_webi=(bat rg fd jq yq k9s ShellCheck shfmt)
    for p in "${tools_by_webi[@]}"; do
        install_by_webinstall "${p}"
    done
}