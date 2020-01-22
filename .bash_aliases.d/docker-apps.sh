
# htpasswd
htpasswd_docker() { docker run --rm httpd:2.4-alpine htpasswd -nbB ${1} ${2} ;};

# portainer
# https://github.com/portainer/portainer
get_portainer_container_id() { get_container_id_by_name "portainer" && portainer_container_id=${get_container_id} ;};
dockerGUI_func() {
  #portainer_container_id=$(get_portainer_container_id)
  # portainer_container_id=$(docker container ls -a --filter name="portainer" | tail -n +2 | awk '{print($1)}')
  #if [[ ${portainer_container_id} != "" ]] ; then
  #  # echo "Remove old portainer container: ${portainer_container_id}"
  #  docker stop ${portainer_container_id} &> /dev/null
  #  docker rm -v -f ${portainer_container_id} &> /dev/null
  #  docker rmi -f ${portainer_container_id} &> /dev/null
  #fi
  docker rm portainer > /dev/null
  docker rmi portainer/portainer:latest > /dev/null
  docker run -d -p 9000:9000 --name portainer \
    --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    portainer/portainer \
    -H unix:///var/run/docker.sock \
    --no-auth \
    &> /dev/null && \
  firefox "http://0.0.0.0:9000/#/dashboard" &> /dev/null && \
  wmctrl -r "Portainer" -t 8
};
alias dockerGUI="dockerGUI_func &"
alias portainer="dockerGUI"

# htop
alias htop_docker="docker run --rm -it --pid host frapsoft/htop"
alias htop=htop_docker

# ctop
# https://github.com/bcicen/ctop
ctop_docker() {
  docker run --rm -ti \
    --name=ctop \
    -v /var/run/docker.sock:/var/run/docker.sock \
    quay.io/vektorlab/ctop:latest
};
alias ctop="ctop_docker"

# dive
# https://github.com/wagoodman/dive
dive() {
  docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    wagoodman/dive:latest
};

# dockviz
# https://github.com/justone/dockviz
alias dockviz="docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock nate/dockviz"