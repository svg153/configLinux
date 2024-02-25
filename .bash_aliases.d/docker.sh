#
alias dcoker="docker"
alias dkr="docker"
alias dockre="docker"

alias di="docker images"

alias docker_list_containers_all='docker container ls -a -q | tr "\n" " "'
alias docker_stop_all='docker stop $(docker ps -a -q | tr "\n" " ")'     # stop all containers
alias docker_rm_cont_all='docker rm $(docker ps -a -q | tr "\n" " ")'       # remove all containers
alias docker_list_images_all='docker images -q | tr "\n" " "' # list all docker images
alias docker_rm_images_all='docker rmi -f $(docker_list_images_all)'  # remove all docker images
alias docker_list_volumes_all='docker volume ls -q | tr "\n" " "' # list all volumes images
alias docker_rm_volumes_all='docker volumes rm $(docker_list_volumes_all)'  # remove all docker volume
alias docker_clean_all="docker_stop_all; docker_rm_cont_all; docker_rm_images_all; docker_rm_volumes_all"  # clean all docker containers, images and volumes
alias docker_remove_everything="docker system prune --all --volume"

# TODO: test this function
docker_rm_images()
{
  if [ -n "$1" ]; then
    docker rmi -f $(docker images -q --filter "reference=$1")
  elif [ -x "$(command -v fzf)" ]; then
    images_to_remove=$(docker images -a | fzf --multi --header-lines=1 | awk '{print $3}')
    # check if the are any container that depends on the image
    if [ -z "$images_to_remove" ]; then
      echo "No images selected"
      return
    fi
    for image in $images_to_remove; do
      containers=$(docker container ls -a --filter "ancestor=$image" --format "{{.ID}}")
      if [ -n "$containers" ]; then
        echo "The following containers depend on $image:"
        docker container ls -a --filter "ancestor=$image" --format "{{.ID}} {{.Names}}"
        echo "Removing the container..."
        docker rm -f $containers
      fi
    done
    docker rmi -f $images_to_remove
  else
    echo "Usage: docker_rm_images <image_name> or install fzf to use interactive mode"
  fi
}

# TODO: test this function
docker_rm_cont()
{
  if [ -n "$1" ]; then
    docker rm -f $(docker container ls -a --filter "name=$1" --format "{{.ID}}")
  elif [ -x "$(command -v fzf)" ]; then
    docker container ls -a | fzf --multi --header-lines=1 | awk '{print $1}' | xargs --no-run-if-empty docker rm -f
  else
    echo "Usage: docker_rm_cont <container_name> or install fzf to use interactive mode"
  fi
}

docker_enter()
{
  docker run -it "$1" /bin/bash
}

docker_rm_c_exited()
{
  docker ps --filter "status=exited" --format "{{.ID}}" | awk '{print $1}' | xargs --no-run-if-empty docker rm
}

# get_container_id_by_name() { local get_container_id=$(docker container ls -a --filter name="$1" | tail -n +2 | awk '{print($1)}');};
get_container_id_by_name()
{
  docker container ls -a --filter name="$1" | tail -n +2 | awk '{print $1}'
}
