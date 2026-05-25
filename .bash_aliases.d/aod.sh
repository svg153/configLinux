

get_androtest_container_id() { androtest_container_id=$(docker ps -a | grep androtest | awk '{print $1}');};

docker_stop_androtest() {
  # get_androtest_container_id()
  androtest_container_id=$(docker ps -a | grep androtest | awk '{print $1}')
  if [[ ${androtest_container_id} == "" ]] ; then
    echo "Any androtest container running"
  else
    docker stop ${androtest_container_id}
  fi
};

docker_enter_androtest-test() {
  TOOL=$1
  C=androtest-test-${TOOL:-puma}
  AP=~/REPOSITORIOS/androtest-test
  ANDROTEST_GUEST_HOME=${ANDROTEST_GUEST_HOME:-$(printf '/%s/%s' 'home' "${ANDROTEST_GUEST_USER:-vagrant}")}
  [[ ! -d $AP ]] && echo "dir: $AP - not exist" && exit 1
  cd $AP
  docker run --publish-all --privileged \
    -v $(pwd)/lib:${ANDROTEST_GUEST_HOME}/lib:rw \
    -v $(pwd)/results:${ANDROTEST_GUEST_HOME}/results:rw \
    -v $(pwd)/subjects:${ANDROTEST_GUEST_HOME}/subjects:rw \
    -v $(pwd)/scripts:${ANDROTEST_GUEST_HOME}/scripts:rw \
    -v $(pwd)/tools:${ANDROTEST_GUEST_HOME}/tools:rw \
    -i $C /bin/bash
};

alias adc="docker build --tag androtest-docker ."
alias ade="docker run --interactive --rm --tty androtest-docker bash"

alias up_run1="cd ~/vagrant/androtest && vagrant up run1 && cd"
alias down_run1="cd ~/vagrant/androtest && vagrant halt run1 && cd"
alias ssh_run1="ssh vagrant@127.0.0.1 -p 2222"
alias start_run1="up_run1 && ssh_run1"

alias up_run2="cd ~/vagrant/androtest && vagrant up run2 && cd"
alias down_run2="cd ~/vagrant/androtest && vagrant halt run2 && cd"
alias ssh_run2="ssh vagrant@127.0.0.1 -p 2200"
alias start_run2="up_run2 && ssh_run2"
