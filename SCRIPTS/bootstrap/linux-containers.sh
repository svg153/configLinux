#!/usr/bin/env bash

function install_docker()
{
    if [[ ${isWSL} == "true" ]]; then
        if check_if_program_is_installed_in_windows "docker"; then
            echo "Docker Desktop is installed in Windows"
        else
            echo "Docker Desktop is not installed in Windows"
            echo "Install Docker on Windows WSL without Docker Desktop"

            sudo apt update && sudo apt upgrade

            if check_if_program_is_installed "docker"; then
                echo "Docker is already installed"
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

                if getent group | grep 36257; then
                    sudo sed -i -e 's/^\(docker:x\):[^:]\+/\1:36257/' /etc/group
                else
                    all_ids=$(seq 1000 65535)
                    possible_ids=$(echo ${all_ids} | grep -v -E "$(getent group | cut -d: -f3 | grep -E '^[0-9]{4}' | sort -g)")
                    middle_id=$(echo ${possible_ids} | wc -l | awk '{print $1/2}')
                    if check_if_program_is_installed "groupmod"; then
                        sudo groupmod -g ${middle_id} docker
                    else
                        sudo sed -i -e 's/^\(docker:x\):[^:]\+/\1:'$(echo ${middle_id})'/' /etc/group
                    fi
                fi

                DOCKER_DIR="/mnt/wsl/shared-docker"
                [[ ! -d "$DOCKER_DIR" ]] && sudo mkdir -pm o=,ug=rwx "$DOCKER_DIR"
                sudo chgrp docker "$DOCKER_DIR"

                [[ ! -d /etc/docker ]] && sudo mkdir -p /etc/docker
                if [[ -f /etc/docker/daemon.json ]]; then
                    if grep -q '"hosts":' /etc/docker/daemon.json; then
                        sudo sed -i -e 's/\("hosts":\s*\)\[[^]]*\]/\1["unix:\/\/'"$DOCKER_DIR"'\/docker.sock"]/' /etc/docker/daemon.json
                    else
                        if check_if_program_is_installed "jq"; then
                            jq '.hosts = ["unix://'"$DOCKER_DIR"'/docker.sock"]' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json
                        else
                            log warn "edit /etc/docker/daemon.json and add the following line: \"hosts\": [\"unix://${DOCKER_DIR}/docker.sock\"]"
                        fi
                    fi

                    if grep -q '"iptables":\s*false' /etc/docker/daemon.json; then
                        sudo sed -i -e 's/\("iptables":\s*\)false/\1true/' /etc/docker/daemon.json
                    elif grep -q '"iptables":\s*true' /etc/docker/daemon.json; then
                        log info "iptables is already set to true"
                    else
                        if check_if_program_is_installed "jq"; then
                            jq '.iptables = true' /etc/docker/daemon.json | sudo tee /etc/docker/daemon.json
                        else
                            log warn "edit /etc/docker/daemon.json and add the following line: \"iptables\": true"
                        fi
                    fi
                else
                    echo '{"hosts": ["unix://'"$DOCKER_DIR"'/docker.sock"], "iptables": true}' | sudo tee /etc/docker/daemon.json
                fi
            fi
        fi
    else
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh ./get-docker.sh --dry-run
        rm -rf get-docker.sh

        sudo docker run hello-world
        sudo groupadd docker || true
        sudo usermod -aG docker $USER
        docker run hello-world
        sudo systemctl enable docker
    fi
}

function install_podman()
{
    install podman
}

function install_minikube()
{
    if [[ -x "$(command -v minikube)" ]]; then
        minikube version
        return 0
    fi

    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
    && sudo mv minikube-linux-amd64 /usr/local/bin/minikube \
    && sudo chmod +x /usr/local/bin/minikube \
    && minikube start

    minikube version
}

function install_kubectx()
{
    sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
    sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
    sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

    if [[ -d ~/.oh-my-zsh/custom/completions ]]; then
        mkdir -p ~/.oh-my-zsh/custom/completions
        chmod -R 755 ~/.oh-my-zsh/custom/completions
        ln -s /opt/kubectx/completion/_kubectx.zsh ~/.oh-my-zsh/custom/completions/_kubectx.zsh
        ln -s /opt/kubectx/completion/_kubens.zsh ~/.oh-my-zsh/custom/completions/_kubens.zsh
    fi
}

function install_container_tooling_bundle()
{
    install_docker
    install_minikube
    install_kubectx
}
