
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

# ocrmypdf
# https://github.com/jbarlow83/OCRmyPDF
alias ocrmypdf='docker run --rm  -i --user "$(id -u):$(id -g)" --workdir /data -v "$PWD:/data" jbarlow83/ocrmypdf'

# tldr pages
# https://github.com/s3than/docker-tldr
alias tldr='docker run -it s3than/tldr'

# kubescape
# https://github.com/armosec/kubescape
kubescape() {
  docker run -v $(pwd)/$1:/app/example.yaml quay.io/armosec/kubescape scan framework nsa /app/example.yaml
}

# yq
# https://github.com/mikefarah/yq
yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq "$@"
}
# json2yaml
alias json2yaml="jq -r yamlify2"

# k6
# https://github.com/grafana/k6
alias k6="docker run -i loadimpact/k6"
alias k6r="k6 run - <"

# shellcheck
# https://github.com/koalaman/shellcheck
alias shellcheck="docker run --rm -v \"$PWD:/mnt\" koalaman/shellcheck:stable"
alias shfmt="docker run --rm -u \"$(id -u):$(id -g)\" -v \"$PWD:/mnt\" -w /mnt mvdan/shfmt:latest"

# terrascan
# https://github.com/accurics/terrascan
alias terrascan="docker run --rm -it -v \"$(pwd):/iac\" -w /iac accurics/terrascan"

# diagrams
# https://github.com/mingrammer/diagrams -> Docker: https://github.com/mujahidk/python-diagrams
# - In Go languaje: https://github.com/blushft/go-diagrams
alias diagrams="docker run -it --rm -v \"$PWD:/diagrams/scripts/\" -w /diagrams/scripts/ mjdk/diagrams hello-world.py"

# testssl
# https://github.com/drwetter/testssl.sh
alias testssl="docker run --rm -it docker.io/drwetter/testssl.sh"

# plantuml
# https://plantuml.com/es/
#   - https://paregov.net/setup-plantuml-with-docker-and-visual-studio-code-locally/
# alias plantuml="docker run --rm -v \"$PWD:/workdir\" plantuml/plantuml -tsvg"
alias plantuml="docker run -d -p 8080:8080 plantuml/plantuml-server:jetty"

# dasel
# https://daseldocs.tomwright.me/installation#docker
alias dasel="docker run -i --rm ghcr.io/tomwright/dasel:latest"