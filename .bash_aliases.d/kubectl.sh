alias k="kubectl"
complete -F __start_kubectl k

if [[ -f ~/.kube/config ]]; then
    export KUBECONFIG=~/.kube/config
elif [[ -d ~/.kube/configs ]]; then
    export KUBECONFIG=$(find -L ~/.kube/configs -type f | sed ':a;N;s/\n/:/;ba')
fi

alias minikubectl="minikube kubectl --"

alias kx='kubectx'

#
# tools
#
alias k9='k9s'
