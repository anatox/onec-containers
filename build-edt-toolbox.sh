#!/usr/bin/env bash
set -eo pipefail

if [[ "$EDT_VERSION" == 2024* ]] || [[ "$EDT_VERSION" == 2025* ]] || [[ "$EDT_VERSION" == 2026* ]]; then
    INSTALLER_BASE_IMAGE="eclipse-temurin"
    INSTALLER_BASE_TAG="${OPENJDK_VERSION}-jdk-noble"
else
    INSTALLER_BASE_IMAGE="eclipse-temurin"
    INSTALLER_BASE_TAG="11-jdk-focal"
fi

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

echo "=== Building oscript-downloader ==="
docker build \
    --pull \
    --build-arg BASE_IMAGE=ubuntu \
    --build-arg BASE_TAG=24.04 \
    --build-arg "ONESCRIPT_VERSION=$ONESCRIPT_VERSION" \
    --build-arg ONESCRIPT_PACKAGES="yard" \
    -t localhost/oscript-downloader:latest \
    -t oscript-downloader:latest \
    -f oscript/Containerfile \
    "${last_args[@]}"

echo "=== Building edt-toolbox ==="
docker build \
    --build-arg "ONEC_USERNAME=$ONEC_USERNAME" \
    --build-arg "ONEC_PASSWORD=$ONEC_PASSWORD" \
    --build-arg "EDT_VERSION=$EDT_VERSION" \
    --build-arg "OPENJDK_VERSION=$OPENJDK_VERSION" \
    --build-arg "INSTALLER_BASE_IMAGE=$INSTALLER_BASE_IMAGE" \
    --build-arg "INSTALLER_BASE_TAG=$INSTALLER_BASE_TAG" \
    -t localhost/edt-toolbox:"$EDT_VERSION" \
    -t localhost/edt-toolbox:latest \
    -f edt-toolbox/Containerfile \
    "${last_args[@]}"

echo "=== Build complete: edt-toolbox:$EDT_VERSION ==="

if [ "${PUSH}" = 'true' ]; then
    if [ -z "${DOCKER_REGISTRY_URL}" ]; then
        echo "ERROR: DOCKER_REGISTRY_URL must be set when PUSH=true"
        exit 1
    fi
    echo "=== Pushing edt-toolbox to ${DOCKER_REGISTRY_URL} ==="
    docker tag localhost/edt-toolbox:"$EDT_VERSION" "$DOCKER_REGISTRY_URL/edt-toolbox:$EDT_VERSION"
    docker tag localhost/edt-toolbox:latest             "$DOCKER_REGISTRY_URL/edt-toolbox:latest"
    docker push "$DOCKER_REGISTRY_URL/edt-toolbox:$EDT_VERSION"
    docker push "$DOCKER_REGISTRY_URL/edt-toolbox:latest"
    echo "=== Push complete ==="
else
    echo "=== Skipping push (set PUSH=true to enable) ==="
fi
