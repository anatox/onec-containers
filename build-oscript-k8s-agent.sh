#!/usr/bin/env bash
set -eo pipefail


last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

docker build \
    --pull \
    --build-arg BASE_IMAGE=eclipse-temurin \
    --build-arg "BASE_TAG=$OPENJDK_VERSION" \
    -t localhost/oscript-jdk:latest \
    -f oscript/Containerfile \
    "${last_args[@]}"

docker build \
    --build-arg BASE_IMAGE=localhost/oscript-jdk \
    --build-arg BASE_TAG=latest \
    -t localhost/oscript-jdk-s6:latest \
    -f s6-overlay/Containerfile \
    "${last_args[@]}"

docker build \
    --build-arg BASE_IMAGE=localhost/oscript-jdk-s6 \
    --build-arg BASE_TAG=latest \
    -t localhost/oscript-agent:latest \
    -f k8s-jenkins-agent/Containerfile \
    "${last_args[@]}"

if [[ "$PUSH" = "true" && -n "$DOCKER_REGISTRY_URL" ]]; then
    docker tag localhost/oscript-jdk-s6:latest "$DOCKER_REGISTRY_URL/oscript-jdk-s6:latest"
    docker push "$DOCKER_REGISTRY_URL/oscript-jdk-s6:latest"
    docker tag localhost/oscript-agent:latest "$DOCKER_REGISTRY_URL/oscript-agent:latest"
    docker push "$DOCKER_REGISTRY_URL/oscript-agent:latest"
else
    echo "PUSH not enabled or DOCKER_REGISTRY_URL not set, skipping push."
fi
