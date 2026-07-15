#!/usr/bin/env bash
set -eo pipefail

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

export OPENJDK_VERSION="${OPENJDK_VERSION:-17}"
export ONESCRIPT_VERSION="${ONESCRIPT_VERSION:-2.1.0}"

echo "=== oscript-jdk ==="
buildah build \
    --build-arg "BASE_IMAGE=eclipse-temurin:$OPENJDK_VERSION-jdk-resolute" \
    --build-arg "ONESCRIPT_VERSION=$ONESCRIPT_VERSION" \
    -t localhost/oscript-jdk:latest \
    -t localhost/oscript-jdk:local \
    -f oscript/Containerfile \
    "${last_args[@]}"

echo "=== oscript-jdk-s6 ==="
buildah build \
    --build-arg BASE_IMAGE=localhost/oscript-jdk:latest \
    -t localhost/oscript-jdk-s6:latest \
    -t localhost/oscript-jdk-s6:local \
    -f s6-overlay/Containerfile \
    "${last_args[@]}"

echo "=== oscript-agent ==="
buildah build \
    --build-arg BASE_IMAGE=localhost/oscript-jdk-s6:latest \
    -t localhost/oscript-agent:latest \
    -t localhost/oscript-agent:local \
    -f k8s-jenkins-agent/Containerfile \
    "${last_args[@]}"

if [ "${PUSH}" = 'true' ]; then
    if [ -z "${CONTAINER_REGISTRY_URL}" ]; then
        echo "ОШИБКА: CONTAINER_REGISTRY_URL должен быть задан при PUSH=true"
        exit 1
    fi
    echo "=== Публикация ==="
    buildah push localhost/oscript-jdk-s6:latest "$CONTAINER_REGISTRY_URL/oscript-jdk-s6:latest"
    buildah push localhost/oscript-agent:latest "$CONTAINER_REGISTRY_URL/oscript-agent:latest"
else
    echo "=== Публикация пропущена (PUSH=true для включения) ==="
fi
