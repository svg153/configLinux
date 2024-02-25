# # https://dev.to/bowmanjd/using-podman-on-windows-subsystem-for-linux-wsl-58ji
# set -x
# if [[ -x "$(command -v podman)" ]]; then
#   # Define runtime dir for podman socket
#   if [[ -z "$XDG_RUNTIME_DIR" ]]; then
#     export XDG_RUNTIME_DIR=/run/user/$UID
#     if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
#       export XDG_RUNTIME_DIR=/tmp/$USER-runtime
#       if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
#         mkdir -m 0700 "$XDG_RUNTIME_DIR"
#       fi
#     fi
#   fi
#   # Check if podman service is running (rootless), and start if not.
#   if ! pgrep -f -x 'podman system service -t 0' > /dev/null;then
#     podman system service -t 0 > /dev/null 2>&1 &
#   fi
#   # Define DOCKER_HOST to podman socket, so docker-compose can work with it
#   # I've installed docker-compose using: pip3 install docker-compose from my user (non-root)
#   DOCKER_HOST=`echo "unix://${XDG_RUNTIME_DIR}/podman/podman.sock"`
#   export DOCKER_HOST
# fi
# set +x