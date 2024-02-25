isWSL=$(uname -a | grep WSL | wc -l)

if [ $isWSL -eq 1 ]; then

    # if /bin/docker-service 
    if [ -f $HOME/bin/docker-service.sh ]; then
        . $HOME/bin/docker-service.sh "Ubuntu-22.04"
    fi
    
    # check if docker is completely installed inside WSL without dockerd desktop    
    DOCKER_SOCK="/mnt/wsl/shared-docker/docker.sock"
    test -S "$DOCKER_SOCK" && export DOCKER_HOST="unix://$DOCKER_SOCK"
fi
