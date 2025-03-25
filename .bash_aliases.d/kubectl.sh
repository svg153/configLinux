alias k="kubectl"
complete -F __start_kubectl k

export KUBECONFIG=$(find -L ~/.kube/configs -type f | sed ':a;N;s/\n/:/;ba')

alias minikubectl="minikube kubectl --"

alias kx='kubectx'

#
# tools
#
alias k9='k9s'
