#!/bin/bash

set -e
set -u

# RUN BEFORE:
# 1º) user must be in sudoers
#         * su && apt-get install sudo && adduser ${USER} sudo && exit
#         * reboot
# 2º) sudo apt-get install git && mkdir ~/REPOSITORIOS && git clone https://github.com/svg153/configLinux.git ~/REPOSITORIOS/configLinux/

# TODO: check this lines, only for debian
# configure the /etc/apt/sources.list
# sudo mv /etc/apt/sources.list /etc/apt/sources.list.OLD
# sudo cp ./sources.list /etc/apt/
# sudo sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list


# update and upgrade only is the system has apt-get (debian, ubuntu, etc)
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

#
# VARS
#

USER_NAME="Sergio Valverde"
PERSONAL_EMAIL=""
COMPANY_NAME=""
COMPANY_USER_NAME=""
COMPANY_USER_EMAIL=""


MODE=${1:-desktop}
MODE_DESKTOP="desktop"
MODE_LAPTOP="laptop"

PROGRAMAS_PATH="$(eval echo ~/PROGRAMAS)"
REPOS_PATH="$(eval echo ~/REPOSITORIOS)"
CONFIG_PATH="${REPOS_PATH}/configLinux"

# check if the system is WSL
isWSL=$(uname -a | grep WSL | wc -l)

#
# VARS
#



#
# ALIASES
#
function aptt() {
    sudo apt -qq -y $@
}

function install_by_apt() {
    aptt install $@
}

function install_by_yum() {
   sudo yum -y install $@
}

function install_by_pgkmanager() {
    if [[ -x "$(command -v apt-get)" ]]; then
        install_by_apt $@
    elif [[ -x "$(command -v yum)" ]]; then
        install_by_yum $@
    else
        echo "Package manager not found"
        return 1
    fi
}

function get_os_distribution() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo $NAME
  elif type lsb_release >/dev/null 2>&1; then
    echo $(lsb_release -si)
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    echo $DISTRIB_ID
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
    install_by_pgkmanager $@
}
function remove() {
    aptt remove $@
}
function update() {
    aptt update $@
}

function check_if_program_is_installed() {
    local p=$1
    [[ $# -ne 1 ]] && echo "Usage: check_if_program_is_installed <program>" && return 1
    [[ -z "${p}" ]] && echo "check_if_program_is_installed: program is empty" && return 1
    [[ -x "$(command -v ${p})" ]] && return 0
    return 1
}

function check_if_program_is_installed_in_windows() {
    local p=$1
    [[ $# -ne 1 ]] && echo "Usage: check_if_program_is_installed_in_windows <program>" && return 1
    [[ -z "${p}" ]] && echo "check_if_program_is_installed_in_windows: program is empty" && return 1
    powershell.exe -Command "Get-Command -Name ${p} -ErrorAction SilentlyContinue" > /dev/null
}

#
# ALIASES
#



#
# FUNCTIONS
#

function log() {
    local level=$1
    local msg=$2
    local color

    case $level in
        info)
            color="\e[32m"  # Green color for info level
            ;;
        warning | warn)
            color="\e[33m"  # Yellow color for warning level
            ;;
        error)
            color="\e[31m"  # Red color for error level
            ;;
        *)
            color="\e[0m"   # Default color
            ;;
    esac

    echo -e "${color}[${level}] ${msg}\e[0m"
}

function create_symlink()
{
    if [[ $# -ne 2 ]]; then
        echo "Usage: create_symlink <source_file> <target_file>"
        return 1
    fi

    local source_file=$1
    local target_file=$2

    if [[ -f $target_file ]]; then
        rm $target_file
    elif [[ -L $target_file ]]; then
        unlink $target_file
    fi

    # fix target_file
    target_file=$(echo $target_file | sed 's/\/\//\//g')
    source_file=$(eval echo $source_file)
    target_file=$(eval echo $target_file)

    ln -s $source_file $target_file
}

function make_folder_structure()
{
    mkdir -p ${PROGRAMAS_PATH}
    mkdir -p ~/.fonts
    mkdir -p ~/.icons

    create_symlink ${CONFIG_PATH}/.include_d ~/.include_d
    create_symlink ${CONFIG_PATH}/.aliases ~/.aliases
    create_symlink ${CONFIG_PATH}/.bashrc ~/.bashrc
    create_symlink ${CONFIG_PATH}/.bash_prompt ~/.bash_prompt
    create_symlink ${CONFIG_PATH}/.bash_aliases ~/.bash_aliases
    create_symlink ${CONFIG_PATH}/.bash_aliases.d ~/.bash_aliases.d
    create_symlink ${CONFIG_PATH}/.bash_completion ~/.bash_completion
    create_symlink ${CONFIG_PATH}/.bash_completion.d ~/.bash_completion.d
    create_symlink ${CONFIG_PATH}/.rc ~/.rc
    create_symlink ${CONFIG_PATH}/.rc.d ~/.rc.d
    create_symlink ${CONFIG_PATH}/.profile ~/.profile
    create_symlink ${CONFIG_PATH}/SCRIPTS ~/SCRIPTS

    # .config
    create_symlink ${CONFIG_PATH}/.config ~/.config
    # create_symlink ${CONFIG_PATH}/.config/flameshot/ ~/.config/flameshot
    # create_symlink ${CONFIG_PATH}/.config/envman/ ~/.config/envman
    # create_symlink ${CONFIG_PATH}/.config/terminator/ ~/.config/terminator
    # create_symlink ${CONFIG_PATH}/.config/wtf/ ~/.config/wtf
    # create_symlink ${CONFIG_PATH}/.config/xfce/ ~/.config/xfce
}

function install_bash_tools()
{
    # z
    git clone https://github.com/rupa/z ~/.z.tmp
    mv ~/.z.tmp/z.sh ~/.z
    rm -rf ~/.z.tmp
}

function install_git()
{
    sudo add-apt-repository ppa:git-core/ppa -y \
    && sudo apt update \
    && install_by_pgkmanager git
}

function install_zsh()
{
    install zsh
    
    sh -c "$(wget -O- https://install.ohmyz.sh/)"

    if [[ ${SHELL} != *"zsh"* ]]; then
        # TODO: check if already installed
        # sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

        # configure zsh
        rm ~/.zshrc; ln -s ${CONFIG_PATH}/.zshrc ~/.zshrc

        # ZSH_C="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"
        ZSH_C="~/.oh-my-zsh/custom"

        # install zsh plugins
        OMZsh_C_P="${ZSH_C}/plugins/"

        cd "${OMZsh_C_P}"
        git clone https://github.com/zsh-users/zsh-autosuggestions
        git clone https://github.com/zsh-users/zsh-completions
        git clone https://github.com/z-shell/zsh-navigation-tools
        git clone https://github.com/zsh-users/zsh-syntax-highlighting
        git clone https://github.com/zsh-users/zsh-history-substring-search
        git clone https://github.com/djui/alias-tips.git
        git clone https://github.com/chrissicool/zsh-256color
        git clone https://github.com/ptavares/zsh-terraform
        git clone https://github.com/dmakeienko/azcli.git
        git clone https://github.com/reegnz/jq-zsh-plugin ./jq
        git clone https://github.com/agkozak/zsh-z
        cd -

        install autojump

        OMZsh_C_T="${ZSH_C}/themes/"
        [[ -d ${OMZsh_C_T} ]] && rm -rf ${OMZsh_C_T}
        ln -s ${CONFIG_PATH}/.oh-my-zsh/custom/themes/ ${OMZsh_C_T}/../

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
    # https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#manual
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
}

function install_font_nerdfonts()
{
    install fontconfig

    # # clone
    # git clone https://github.com/powerline/fonts.git --depth=1
    # # install
    # cd fonts
    # ./install.sh
    # # clean-up a bit
    # cd ..
    # rm -rf fonts


    # cd /tmp
    # git clone https://github.com/gabrielelana/awesome-terminal-fonts
    # mkdir -p ~/.fonts
    # cp awesome-terminal-fonts/build/* ~/.fonts
    # fc-cache -fv ~/.fonts
    # mkdir -p ~/.config/fontconfig/conf.d
    # cp awesome-terminal-fonts/config/10-symbols.conf ~/.config/fontconfig/conf.d
    # # echo "Do this 'echo "source ~/.fonts/*.sh" >> ~/.zshrc'"/

    # https://github.com/ryanoasis/nerd-fonts
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

    # OTHER: how to download and install fonts from the command line
    # mkdir -p ~/.local/share/fonts
    # cd ~/.local/share/fonts && curl -fLo "Droid Sans Mono for Powerline Nerd Font Complete.otf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf

    cd ..
    rm -rf nerd-fonts
    set +e

    # https://github.com/ryanoasis/nerd-fonts#font-patcher
    docker run -v ~/.local/share/fonts/:/in -v ~/.local/share/fonts/:/out nerdfonts/patcher --powerline --powerlineextra
    # docker run -v ~/.local/share/fonts/:/in -v ~/.local/share/fonts/:/out nerdfonts/patcher --complete
    sudo chown -R $USER:$USER ~/.local/share/fonts

    fc-cache -fv
}

function install_pyenv()
{
    # https://github.com/pyenv/pyenv

    # https://github.com/pyenv/pyenv/wiki#suggested-build-environment
    sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl \
    libncursesw5-dev xz-utils libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    # https://github.com/pyenv/pyenv#automatic-installer
    curl https://pyenv.run | bash
}


# TODO: 
# function install_docker_pkg()
# {
#     # https://docs.docker.com/engine/install/ubuntu/
#     # Install using the repository
#     sudo apt-get update
#     sudo apt-get install \
#         apt-transport-https \
#         ca-certificates \
#         curl \
#         gnupg \
#         lsb-release
#     . /etc/os-release
#     sudo sh -c "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/docker.gpg] https://download.docker.com/linux/${ID} $(lsb_release -cs) stable\" > /etc/apt/sources.list.d/docker.list"    
# }

function install_docker()
{
    # https://docs.docker.com/engine/install/ubuntu/
    # Install Docker on Windows WSL without Docker Desktop
    if [[ ${isWSL} ]]; then
        if check_if_program_is_installed_in_windows "docker"; then
            # Install Docker on WSL to use Docker Desktop
            # https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script
            echo "Docker Desktop is installed in Windows"
            # TODO: remove
            # curl -fsSL https://get.docker.com -o get-docker.sh
            # sudo sh ./get-docker.sh --dry-run
            # rm -rf get-docker.sh
        else # if docker is not installed in Windows and we want to use docker WSL for Windows
            # Install Docker on Windows WSL without Docker Desktop
            # https://dev.to/bowmanjd/install-docker-on-windows-wsl-without-docker-desktop-34m9
            echo "Docker Desktop is not installed in Windows"
            echo "Install Docker on Windows WSL without Docker Desktop"
            
            # TODO:use this instead of mine https://github.com/bowmanjd/docker-wsl/blob/main/setup-docker.sh
            
            # if distro is Debian or Ubuntu, skip 
            #   - Configure a non-root user
            #   - Configure admin (sudo) access for the non-root user
            #   - Set default user
            
            sudo apt update && sudo apt upgrade
            # if has network problems:
            # echo -e "[network]\ngenerateResolvConf = false" | sudo tee -a /etc/wsl.conf
            # sudo unlink /etc/resolv.conf
            # echo nameserver 1.1.1.1 | sudo tee /etc/resolv.conf
            
            # if docker is already installed, remove it
            if check_if_program_is_installed "docker"; then
                echo "Docker is already installed"
                # https://docs.docker.com/engine/install/ubuntu/#uninstall-old-versions
                # https://docs.docker.com/engine/install/ubuntu/#uninstall-docker-engine
                # TODO: check this packages
                # sudo apt remove \
                #     docker \
                #     docker-engine
                sudo apt-get remove \
                    docker.io \
                    docker-doc \
                    docker-compose \
                    docker-compose-v2 \
                    podman-docker \
                    containerd \
                    runc
                sudo apt-get purge \
                    docker-ce \
                    docker-ce-cli \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin \
                    docker-ce-rootless-extras
                sudo rm -rf /var/lib/docker
                sudo rm -rf /var/lib/containerd
            else
                echo "Docker is not installed"
                sudo apt install --no-install-recommends apt-transport-https ca-certificates curl gnupg2
                sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
                sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
                
                . /etc/os-release
                curl -fsSL https://download..docker.com/linux/${ID}/gpg | sudo tee /etc/apt/trusted.gpg.d/docker.asc
                echo "deb [arch=amd64] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list
                sudo apt update
                sudo apt install docker-ce docker-ce-cli containerd.io

                sudo usermod -aG docker $USER
                
                # Sharing dockerd: choose a common ID for the docker group
                if getent group | grep 36257; then
                    sudo sed -i -e 's/^\(docker:x\):[^:]\+/\1:36257/' /etc/group
                else
                    # find other common ID
                    # get all possible ids, filter only 4 digits, from 1000 to 65535, and sort
                    all_ids=$(seq 1000 65535)
                    # possible_ids  all_ids unless (getent group | cut -d: -f3 | grep -E '^[0-9]{4}' | sort -g)
                    possible_ids=$(echo ${all_ids} | grep -v -E "$(getent group | cut -d: -f3 | grep -E '^[0-9]{4}' | sort -g)")
                    # Take the middle value of the possible_ids
                    middle_id=$(echo ${possible_ids} | wc -l | awk '{print $1/2}')
                    # set the middle_id as the common id
                    # if groupmod is available
                    if check_if_program_is_installed "groupmod"; then
                        sudo groupmod -g ${middle_id} docker
                    else
                        sudo sed -i -e 's/^\(docker:x\):[^:]\+/\1:'$(echo ${middle_id})'/' /etc/group
                    fi
                fi
                
                # prepare a shared directory
                DOCKER_DIR="/mnt/wsl/shared-docker"
                [[ ! -d "$DOCKER_DIR" ]] && sudo mkdir -pm o=,ug=rwx "$DOCKER_DIR"
                sudo chgrp docker "$DOCKER_DIR"
                
                # configure the Docker daemon to use the shared directory
                [[ ! -d /etc/docker ]] && sudo mkdir -p /etc/docker
                if [[ -f /etc/docker/daemon.json ]]; then
                    if grep -q '"hosts":' /etc/docker/daemon.json; then
                        # Docker daemon is already configured
                        sudo sed -i -e 's/\("hosts":\s*\)\[[^]]*\]/\1["unix://'"$DOCKER_DIR"'/docker.sock"]/' /etc/docker/daemon.json
                    else
                        # Docker daemon is not configured
                        # if jq is available
                        if check_if_program_is_installed "jq"; then
                            jq '.hosts = ["unix://'"$DOCKER_DIR"'/docker.sock"]' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json
                        else
                            log warn "edit /etc/docker/daemon.json and add the following line: \"hosts\": [\"unix://${DOCKER_DIR}/docker.sock\"]"
                        fi
                    fi
                    
                    # check and set ipatables=true in daemon.json
                    # cehck if iptables is already set to false
                    if grep -q '"iptables":\s*false' /etc/docker/daemon.json; then
                        # set iptables to true
                        sudo sed -i -e 's/\("iptables":\s*\)false/\1true/' /etc/docker/daemon.json
                    elif grep -q '"iptables":\s*true' /etc/docker/daemon.json; then
                        log info "iptables is already set to true"
                    else # if iptables is not set
                        if check_if_program_is_installed "jq"; then
                            jq '.iptables = true' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json
                        else
                            log warn "edit /etc/docker/daemon.json and add the following line: \"iptables\": true"
                        fi
                    fi
                else
                    # create daemon.json and set the hosts and the iptables
                    echo '{"hosts": ["unix://'"$DOCKER_DIR"'/docker.sock"], "iptables": true}' | sudo tee /etc/docker/daemon.json
                    # https://github.com/MicrosoftDocs/WSL/issues/422
                    #    "bip": "172.17.0.1/28",
                fi
            fi
        fi
    else
        # Add Docker's official GPG key:
        sudo apt-get update
        sudo apt-get install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        
        # Add the repository to Apt sources:
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        
        # Install Docker
        sudo apt install docker-ce docker-ce-cli containerd.io
        
        # TODO: test
        # sudo docker run hello-world
        # sudo groupadd docker
        # sudo usermod -aG docker $USER
        # newgrp docker
        # docker run hello-world
        # sudo systemctl enable docker
    fi
}

function install_podman()
{
    # https://podman.io/getting-started/installation
    # https://dev.to/bowmanjd/using-podman-on-windows-subsystem-for-linux-wsl-58ji
    
    install podman
}

function install_minikube()
{
    if [[ -x "$(command -v minikube)" ]]; then
        minikube version
        return 0
    fi
    
    # https://minikube.sigs.k8s.io/docs/start/
    # TODO: check if works
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
    && sudo apt install minikube-linux-amd64 /usr/local/bin/minikube \
    && rm ./minikube-linux-amd64
    minikube start
    
    # INFO
    # - Podman: https://minikube.sigs.k8s.io/docs/drivers/podman/
}

function install_tfenv()
{
    # tfenv
    # https://github.com/tfutils/tfenv#terraform-version-file
    if [[ -x "$(command -v tfenv)" ]]; then
        tfenv -v
    else
        git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
        # added to path in .rc.d/terraform.sh
        mkdir -p ~/.local/bin/
        ln -s ~/.tfenv/bin/* ~/.local/bin
        which tfenv
        tfenv -v
    fi
}

function install_terraform_with_tfenv()
{
    if [[ -x "$(command -v terraform)" ]]; then
        terraform -version
        return 0
    else
        install_tfenv
    fi

    tfenv install latest
    tfenv use latest
}

function install_terraform()
{
    if [[ -x "$(command -v terraform)" ]]; then
        terraform -version
        return 0
    fi

    # https://developer.hashicorp.com/terraform/install#linux
    sudo apt-get update \
    && sudo apt-get install -y gnupg software-properties-common

    [[ -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]] && sudo rm /usr/share/keyrings/hashicorp-archive-keyring.gpg
    wget -O- https://apt.releases.hashicorp.com/gpg | \
        sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && gpg --no-default-keyring \
        --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
        --fingerprint
    
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update \
    && sudo apt-get install terraform \
    && terraform -help \
    && terraform -help plan \
    
    stdout=$(terraform -install-autocomplete | grep "already installed" | wc -l)
    ret=$?
    if [[ ${ret} -ne 0 ]] && [[ ${stdout} -gt 0 ]]; then
        echo "Terraform autocomplete is already installed"
    fi
}

function install_terraform_tools()
{
    # tflint
    # https://github.com/tighten/tlint
    if [[ -x "$(command -v tflint)" ]]; then
        tflint -v
    else
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    fi

    # tfswitch
    # https://github.com/warrensbox/terraform-switcher
    if [[ -x "$(command -v tfswitch)" ]]; then
        tfswitch -v
    else
        curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh > install.sh
        chmod +x install.sh
        ./install.sh
        rm install.sh                
    fi
    
    # tfsec
    # https://github.com/aquasecurity/tfsec
    if [[ -x "$(command -v tfsec)" ]]; then
        tfsec -v
    else
        go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
    fi
    
    # checkcov
    # https://github.com/bridgecrewio/checkov
    if [[ -x "$(command -v checkov)" ]]; then
        checkov -v
    else
        pip3 install checkov
    fi
    
    # tfautomv
    # https://github.com/busser/tfautomv
    if [[ -x "$(command -v tfautomv)" ]]; then
        tfautomv -v
    else
        curl -sSfL https://raw.githubusercontent.com/busser/tfautomv/main/install.sh | sh
    fi
}

function install_chrome()
{
    if [[ -x "$(command -v google-chrome)" ]]; then
        google-chrome --version
        return 0
    fi

    deb_filename="google-chrome-stable_current_amd64.deb"
    deb_filepath_dw="${PROGRAMAS_PATH}/${deb_filename}"
    wget -O ${deb_filepath_dw} https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb ${PROGRAMAS_PATH}
    sudo dpkg -i ${deb_filepath_dw}
    # fix chrome installation
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

function install_gum()
{
    # only install gum if it is not installed
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

    version=1.1.2
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
  # https://taskfile.dev/installation/#install-script
  if [[ -x "$(command -v task)" ]]; then
    echo "task is already installed"
  else
    sh -c "$(curl --location <https://taskfile.dev/install.sh>)" -- -d -b ~/.local/bin
  fi
}

function install_termium()
{
    # https://codeium.com/blog/termium-codeium-in-terminal-launch
    # https://github.com/Exafunction/codeium
    
    if [[ -x "$(command -v termium)" ]]; then
        termium --help
        return 0
    fi
    
    curl -L https://github.com/Exafunction/codeium/releases/download/termium-v0.2.0/install.sh | bash
    termium auth
}

function install_taskfalcon()
{
    if [[ -x "$(command -v taskfalcon)" ]]; then
        taskfalcon --version
        return 0
    fi

    curl -L https://taskfalcon.org/bin/TaskFalcon-Linux.tgz | tar xz \
        && sudo mv falcon /usr/local/bin/falcon \
        && sudo chmod +x /usr/local/bin/falcon \
        && sudo ln -s /usr/local/bin/falcon /usr/local/bin/taskfalcon \
        && falcon --version
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
}

function install_node()
{
  local os_distribution=$(get_os_distribution)
  
  if [ $os_distribution == "Debian" || $os_distribution == "Ubuntu" ]; then
    curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash - \
    && sudo apt-get install -y nodejs
  elif [ $os_distribution == "CentOS Linux" ]; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo -E bash - \
    &&  sudo yum install nodejs -y --skip-broken && sudo yum install nsolid -y --skip-broken
  else
    echo "OS distribution not supported"
  fi
}

function install_golang()
{
  local -r go_version="1.23.4"
  
  
  wget https://go.dev/dl/go${go_version}.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go${go_version}.linux-amd64.tar.gz
  # if go not in the path
  if ! command -v go &> /dev/null; then
    echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
    source ~/.bashrc
  fi   
}

function install_gh()
{
    if [[ -x "$(command -v gh)" ]]; then
        gh --version
        return 0
    fi
    
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    update
    install gh

    # create_symlink ${CONFIG_PATH}/.config/gh ~/.config/gh

    # auth
    if ! gh auth status; then
        gh auth login
    fi
    
    # Add fingerprint to known_hosts
    ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts # ssh-ed25519
    ssh-keyscan -t ecdsa-sha2-nistp256 github.com  >> ~/.ssh/known_hosts
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts # ssh-rsa
}

function install_gh_extensions(){
    gh_extension=(
        github/gh-copilot
        github/gh-projects
        dlvhdr/gh-dash
        rsese/gh-actions-status
        meiji163/gh-notify
        seachicken/gh-poi
        redraw/gh-install
    )

    if gh auth status; then
        for ext in "${gh_extension[@]}"; do
            install_gh_ext "${ext}"
        done

        if ! gh extension list | grep "matt-bartel/gh-clone-org" && ! gh extension list | grep "svg153/gh-clone-org"; then
            install_gh_ext "matt-bartel/gh-clone-org"
            if [[ -d ~/.local/share/gh/extensions/gh-clone-org-matt ]]; then
                mv ~/.local/share/gh/extensions/gh-clone-org{,-matt}
                mv ~/.local/share/gh/extensions/gh-clone-org-matt/gh-clone-org{,-matt}
            fi

            # create_symlink ${CONFIG_PATH}/.config/gh-dash/ ~/.config/gh-dash # config for dlvhdr/gh-dash

            # my extension
            if [[ ! -d "${REPOS_PATH}/gh-clone-org" ]]; then
                gh repo clone svg153/gh-clone-org ${REPOS_PATH}/gh-clone-org
                ln -s ${REPOS_PATH}/gh-clone-org ~/.local/share/gh/extensions/gh-clone-org-svg153
                ln -s ~/.local/share/gh/extensions/gh-clone-org-svg153 ~/.local/share/gh/extensions/gh-clone-org
            fi
        fi
    else
        log warn "gh_extensions: gh is not authenticated"
    fi
}

function install_gh_ext()
{
    local ext=$1
    [[ $# -ne 1 ]] && echo "Usage: install_gh_extensions <extension>" && return 1
    [[ -z "${ext}" ]] && echo "install_gh_extensions: extension is empty" && return 1
    gh extension install "${ext}"
}

function install_gh_copilot()
{
    if [[ -x "$(command -v github-copilot-cli)" ]]; then
        github-copilot-cli --version
        return 0
    fi
    
    # check that node is installed
    [[ -x "$(command -v node)" ]] || install_node
    # check that node is more than 18
    node_version=$(node -v | cut -d'.' -f1 | cut -d'v' -f2)
    [[ ${node_version} -lt 18 ]] && install_node
    
    sudo npm install -g npm
    sudo npm install -g @githubnext/github-copilot-cli
    
    github-copilot-cli auth
}

function install_github_tools()
{
    # ghorg
    # https://github.com/gabrie30/ghorg
    go install github.com/gabrie30/ghorg@latest
}

function install_by_gh()
{
    local p=$1
    [[ $# -ne 1 ]] && echo "Usage: install_by_gh <github_org_repo>" && return 1
    [[ -z "${p}" ]] && echo "install_by_gh: github_org_repo is empty" && return 1
    gh install "${p}"
}

function install_starship()
{
    sh -c "$(curl -fsSL https://starship.rs/install.sh)"
    # @TODO: ask sudo pass
    if [[ ! -d ~/.config ]]; then
        mkdir -p ~/.config
    fi
    # create_symlink ${CONFIG_PATH}/.config/starship.toml ~/.config/starship.toml
}

function install_azurecli()
{
    [[ -x "$(command -v az)" ]] && return 0

    # https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
    curl -L https://aka.ms/InstallAzureCli | bash
}

function install_azurecli_extentions()
{
    # NOTE: List https://learn.microsoft.com/en-us/cli/azure/azure-cli-extensions-list
    local -r extensions=(
        "azure-devops"
    )
    
    if [[ -x "$(command -v az)" ]]; then
        for ext in "${extensions[@]}"; do
            az extension add --name ${ext}
        done
    else
        log warn "install_azurecli_extentions: az is not installed"
    fi
}

#
# FUNCTIONS
#



#
# BIG FUNCTIONS
#

function install_drivers()
{
    install firmware-linux lshw

    intel=$(lshw | grep CPU | grep Intel | wc -l)
    [[ ${intel} -gt 0 ]] && install intel-microcode
    amd=$(lshw | grep CPU | grep amd | wc -l)
    [[ ${amd} -gt 0 ]] && install amd64-microcode


    # install graphics: https://wiki.debian.org/GraphicsCard

    # AMD or ATI: https://wiki.debian.org/AtiHowTo
    isATI=$(lspci -nn | grep VGA | grep ATI | wc -l)
    [[ ${isATI} -ne 0 ]] && install firmware-linux-nonfree libgl1-mesa-dri xserver-xorg-video-ati
    # OFFICIAL AMD or ATI:
    #    https://wiki.debian.org/ATIProprietary
    #    http://support.amd.com/en-us/kb-articles/Pages/AMDGPU-PRO-Install.aspx

    # Nvidia: https://wiki.debian.org/NvidiaGraphicsDrivers

    # firmware-realtek
    install firmware-realtek

    # wifi
    install wpasupplicant wireless-tools network-manager
    # GUI to manage network connections
    #    https://wiki.debian.org/WiFi/HowToUse
    install network-manager-gnome

    # unclaimed drivers
    unclaimed=$(sudo lshw | grep UNCLAIMED)
    c=$(echo ${unclaimed} | wc -l)
    [[ ${c} -ne 0 ]] && echo "Drivers UNCLAIMED" && echo "${unclaimed}" && exit 1

    unclaimed=$(sudo lspci | grep UNCLAIMED)
    c=$(echo ${unclaimed} | wc -l)
    [[ ${c} -ne 0 ]] && echo "Drivers UNCLAIMED" && echo "${unclaimed}" && exit 1



    # Multimedia codecs
    install \
        libavcodec-extra \
        ffmpeg

    # Volume Control: (Optional, Only for Xfce users)
    install \
        pavucontrol

    # bluetooth
    install \
        bluetooth \
        pulseaudio-module-bluetooth \
        bluewho \
        blueman \
        bluez
}

function clone_common_repos() {
    local -r dw_repos=(
        "0_PERSONAL;ythirion/knowledge-base"
        "0_PERSONAL;svg153/notes"
    )
    
    for repo in "${dw_repos[@]}"; do
        folder=$(echo ${repo} | cut -d';' -f1)
        repo=$(echo ${repo} | cut -d';' -f2)
        repo_name=$(echo ${repo} | cut -d'/' -f2)
        
        [[ -d "${REPOS_PATH}/${folder}" ]] || mkdir -p "${REPOS_PATH}/${folder}"
        [[ -d "${REPOS_PATH}/${folder}/${repo_name}" ]] && continue
        
        # clone
        folder_to_clone="${REPOS_PATH}/${folder}/${repo_name}"
        if [[ -x "$(command -v gh)" ]] && gh auth status; then
            gh repo clone ${repo} ${folder_to_clone}
        else
            git clone git@github.com:${repo}.git ${folder_to_clone}
        fi
    done
}


function create_sshkey_github() {
    mkdir -p ~/.ssh
    
    # PERSONAL
    sshkeyfile="~/.ssh/id_ed25519_github-com"
    ssh-keygen -t ed25519 -C "${PERSONAL_EMAIL}" -f "${sshkeyfile}"
    echo "Host github.com
    HostName github.com
    IdentityFile ${sshkeyfile}
    AddKeysToAgent yes
    User git" >> ~/.ssh/config
    
    # WORK
    sshkeyfile="~/.ssh/id_ed25519_github-internal"
    ssh-keygen -t ed25519 -C "${COMPANY_USER_EMAIL}" -f "${sshkeyfile}"
    echo "Host git.internal.com # TODO: ask for this
    HostName git.internal.com # TODO: ask for this
    IdentityFile ${sshkeyfile}
    AddKeysToAgent yes
    User git" >> ~/.ssh/config    
}

#
# BIG FUNCTIONS
#



#
# MAIN
#


# drivers
if [[ ${isWSL} ]]; then
    echo "No install drivers for WSL"
else
    # TODO: only if not Virtual Machine
    install_drivers
fi

create_sshkey_github

# utils
install bash-completion
install_bash_tools
install_git
install curl vim
install \
    zip unzip unrar \
    xclip \

if [[ ${isWSL} ]]; then
    echo "No install some utils for WSL"
else
    # windows automation tools
    install \
        wmctrl \
        xdotool

    # @TODO: check this packages
    # # package manager
    # install \
    #     synaptic \
    #     apt-xapian-index \
    #     gdebi \
    #     gksu
fi


# folder structure
make_folder_structure

# clone conifLinux if exist pull else clone
if [[ -d "${CONFIG_PATH}/.git" ]]; then
    git -C ${CONFIG_PATH} pull
else
    git clone git@github.com:svg153/configLinux.git ${CONFIG_PATH}
fi

# GIT
# TODO: configure_git function
log info "git"
create_symlink ${CONFIG_PATH}/.gitconfig ~/.gitconfig
create_symlink ${CONFIG_PATH}/.gitconfig.d ~/.gitconfig.d
create_symlink ${CONFIG_PATH}/.git-template ~/.git-template
git config --global init.templateDir ~/.git-template

# personal mail
personal_mail_gitconfig="${CONFIG_PATH}/.gitconfig.d/personal-mail.gitconfig"
if [[ ! -f "${personal_mail_gitconfig}" ]]; then
    if [[ -z "${PERSONAL_EMAIL}" ]]; then
        echo "Enter your personal email: "
        read PERSONAL_EMAIL
    fi
    echo """
[user]
    name = ${USER_NAME}
    email = ${PERSONAL_EMAIL}
    """ > ${personal_mail_gitconfig}
fi

# work mail
# if work folder exists
if [[ ! -d "${CONFIG_PATH}/.gitconfig.d/work" ]]; then
    mkdir -p ${CONFIG_PATH}/.gitconfig.d/work    
fi

if [[ -z "$(ls ${CONFIG_PATH}/.gitconfig.d/work/work-*.gitconfig)" ]]; then
    if [[ -z "${COMPANY_NAME}" ]]; then
        echo "Enter your company name: "
        read COMPANY_NAME
    fi
    work_mail_gitconfig="${CONFIG_PATH}/.gitconfig.d/work/work-${COMPANY_NAME}.gitconfig"
    if [[ ! -f "${work_mail_gitconfig}" ]]; then
        if [[ -z "${COMPANY_USER_NAME}" ]]; then
            echo "Enter your company user name: "
            read COMPANY_USER_NAME
        fi
        if [[ -z "${COMPANY_USER_EMAIL}" ]]; then
            echo "Enter your company user email: "
            read COMPANY_USER_EMAIL
        fi
        echo """
[user]
    name = ${COMPANY_USER_NAME}
    email = ${COMPANY_USER_EMAIL}
        """ > ${work_mail_gitconfig}
    fi
fi

log info "languages"
install_python
install_node
install_by_pgkmanager golang-go
# OR install_golang

log info "github tools"
install_gh
install_gh_extensions
install_gh_copilot
install_github_tools

log info "zsh and .oh-my-zsh"
install_zsh

log info "git GUI"
if [[ ${isWSL} ]]; then
    log info "No install git-gui and gitk for WSL"
else
    install \
        git-gui gitk \
        meld
fi

# install: openvpn
log info "openvpn"
if [[ ${isWSL} ]]; then
    log info "No install openvpn for WSL"
else
    install \
        openvpm \
        resolvconf \
        network-manager-openvpn-gnome
fi

# install: dependencies for compiling
# install_pyenv # @TODO: check if it is necessary

log info "docker"
install_docker

# log info "podman"
# install_podman

log info "minikube"
install_minikube

if [[ ${isWSL} ]]; then
    echo "No install chrome and telegram for WSL"
else
    install_chrome
    install_telegram
fi

# @TODO: Install VSCODE
if [[ ${isWSL} ]]; then
    echo "No install vscode for WSL"
else
    install_vscode
fi

# Tools
install_by_pgkmanager w3m
install_gum
install_ijq
install_starship

# Azure
install_azurecli
install_azurecli_extentions

# Terraform 
install_tfenv
install_terraform_with_tfenv # use tfenv to install terraform instead of install_terraform
install_terraform_tools

pip3 install \
    pre-commit

install_fzf
install_gotask
install_termium
install_taskfalcon

install_webinstall
tools_by_webi=(bat rg fd jq yq)
tools_by_webi+=(k9s)
tools_by_webi+=(ShellCheck shfmt)
# tools_by_webi+=(nerdfonts) # @TODO:
for p in "${tools_by_webi[@]}"; do
    install_by_webinstall "${p}"
done
# create_symlink ${CONFIG_PATH}/.config/bat/ ~/.config/bat
# create_symlink ${CONFIG_PATH}/.config/k9s/ ~/.config/k9s

# tools that are not in webinstall, and his package is in github
tools_by_github=(
    wtfutil/wtf
    noahgorstein/jqp
    go-task/task
    altsem/gitu
)
# NOTE: go-task/task move to install_gotask
# multiprocessio/ds # TODO: Failed

# @TODO: interactive install...
#    - https://github.com/redraw/gh-install/issues/5
#        - https://github.com/wimpysworld/deb-get
#        - https://github.com/devops-works/binenv
#        - https://github.com/jooola/gh-release-install
#        - https://github.com/Rishang/install-release

for p in "${tools_by_github[@]}"; do
    install_by_gh "${p}"
done
# create_symlink ${CONFIG_PATH}/.config/gitu/ ~/.config/gitu

#
# PROGRAMS
#



#
# APPS
#

if [[ ${isWSL} ]]; then
    echo "No install apps for WSL"
else
    # xfce4
    install \
        xfce4-whiskermenu-plugin \
        menulibre \
        xfce4-clipman \
        xfce4-panel-dev \
        xfce4-power-manager \
        xfce4-screenshooter \
        xfce4-taskmanager \
        xfce4-terminal \
        xfce4-xkb-plugin

    # @TODO: Check this apps:
    #file-roller
    #evince
    #doidon
    #clementine
    #shotwell
    #build-essential
    #debian-keyring
    #mousepad
    #p7zip policykit-1-gnome p7zip-full
    #aspell aspell-en hunspell hunspell-en-us mythes-en-us
    #ristretto
    #thunar-archive-plugin
    #ufw
    #xarchiver
    #xserver-xorg-input-synaptics

    install rsync \
        qalculate vlc gimp \
        gparted gnome-disk-utility

    # flameshot (new shutter)
    install flameshot
    flameshot_configfile=".config/flameshot/flameshot.ini"
    rm ${flameshot_configfile}
    ln -s ${CONFIG_PATH}/${flameshot_configfile} ~/${flameshot_configfile}
fi


#
# APPS
#


#
# CUSTOMIZATION
#

# TODO: check wheel scroll https://askubuntu.com/a/304653

if [[ ${isWSL} ]]; then
    echo "No customization for WSL"
else
    # fonts
    # TODO: check fonts name to install
    # install \
    #     fonts-dejavu \
    #     fonts-dejavu-extra \
    #     fonts-droid-fallback \
    #     fonts-freefont-ttf \
    #     fonts-liberation \
    #     fonts-noto \
    #     fonts-noto-mono \
    #     fonts-opensymbol \
    #     ttf-bitstream-vera \
    #     ttf-dejavu \
    #     ttf-dejavu-core \
    #     ttf-dejavu-extra \
    #     ttf-freefont \
    #     ttf-liberation \
    #     ttf-mscorefonts-installer \
    #     qt4-qtconfig

    # lightdm
    echo '[SeatDefaults]' >> /usr/share/lightdm/lightdm.conf.d/01_my.conf
    echo 'greeter-hide-users=false' >> /usr/share/lightdm/lightdm.conf.d/01_my.conf

    # themes
    # Numix: https://github.com/numixproject/numix-gtk-theme
    sudo add-apt-repository ppa:numix/ppa
    sudo apt update
    sudo apt install numix-*

    # Xfce-dust-svg153
    sudo cp -r ./themes/* /usr/share/themes/

    # xfce
    os_xfce4="~/.config/xfce4"
    os_xfconf="${os_xfce4}/xfconf"
    repo_xfce4="${CONFIG_PATH}/.config/xfce4"
    repo_xfconf="${repo_xfce4}/xfconf"

    mv ${os_xfce4}{,.ori}
    ln -s ${repo_xfce4} ${os_xfce4}

    xfce_mode="${MODE_DESKTOP}"
    [[ "${MODE}" == "${MODE_LAPTOP}" ]] && xfce_mode="${MODE_LAPTOP}"
    ln -s ${repo_xfconf}/xfce-perchannel-xml/{xfce4-power-manager-${xfce_mode}.xml,xfce4-power-manager.xml}

    # config keyboard
    keyboard_filepath_ori="/etc/default/keyboard"
    keyboard_filepath_mine="${CONFIG_PATH}/keyboard"
    sudo cp ${keyboard_filepath_ori} ${keyboard_filepath_ori}.OLD
    sudo rm ${keyboard_filepath_ori}
    if [[ -e "${keyboard_filepath_mine}" ]]; then
    sudo ln -s ${keyboard_filepath_mine} ${keyboard_filepath_ori}
    if [[ $? -ne 0 ]]; then
        sudo cp ${keyboard_filepath_mine} ${keyboard_filepath_ori}
    fi
    fi
    sudo dpkg-reconfigure -phigh console-setup
fi

#
# CUSTOMIZATION
#


#
# Automation 
#

clone_common_repos

#
# CLEAN
#

sudo apt autoremove
sudo apt clean

#
# CLEAN
#

#
# Thanks:
#    https://linuxpanda.wordpress.com/2016/12/31/things-to-do-after-installing-debian-stretch/
#    https://www.youtube.com/watch?v=BWBHJmAmZgk
#    https://www.youtube.com/watch?v=c60x3nd7cag
#    https://www.youtube.com/watch?v=GR2y0xOIIdI
