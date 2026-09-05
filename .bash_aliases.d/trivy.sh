trivy-docker() {
    docker run \
        --rm \
        -v "/var/run/docker.sock":"/var/run/docker.sock" \
        -v $(pwd)/:/project \
        aquasec/trivy:latest \
        --insecure \
        image \
        $1 \
        --pkg-types os,library \
        --severity CRITICAL,HIGH
}