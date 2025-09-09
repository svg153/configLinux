if command -v kubectl > /dev/null 2>&1; then
    source <(kubectl completion bash)
fi

if command -v minikube > /dev/null 2>&1; then
    source <(minikube completion bash)
fi