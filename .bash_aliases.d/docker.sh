
docker_enter()
{
  docker run -it "$1" /bin/bash
};


docker_rm_c_exited()
{
  docker ps --filter \"status=exited\" --format \"{{.ID}}\" | awk \'{print \$1}\' | xargs --no-run-if-empty docker rm
};

# get_container_id_by_name() { local get_container_id=$(docker container ls -a --filter name="$1" | tail -n +2 | awk '{print($1)}');};
get_container_id_by_name() { docker container ls -a --filter name="$1" | tail -n +2 | awk '{print $1}';};

alias di="docker images"

alias docker_list_containers_all='docker container ls -a -q | tr "\n" " "'
alias docker_stop_all='docker stop $(docker ps -a -q | tr "\n" " ")'     # stop all containers
alias docker_rm_cont_all='docker rm $(docker ps -a -q | tr "\n" " ")'       # remove all containers
alias docker_list_images_all='docker images -q | tr "\n" " "' # list all docker images
alias docker_rm_images_all='docker rmi -f $(docker_list_images_all)'  # remove all docker images
alias docker_list_volumes_all='docker volume ls -q | tr "\n" " "' # list all volumes images
alias docker_rm_volumes_all='docker volumes rm $(docker_list_volumes_all)'  # remove all docker volume
alias docker_clean_all="docker_stop_all; docker_rm_cont_all; docker_rm_images_all"