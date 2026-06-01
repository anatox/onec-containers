#!/usr/bin/env bash
set -eo pipefail

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

echo "=== Building client-toolbox ==="
docker build \
    --build-arg "ONEC_USERNAME=$ONEC_USERNAME" \
    --build-arg "ONEC_PASSWORD=$ONEC_PASSWORD" \
    --build-arg "ONEC_VERSION=$ONEC_VERSION" \
    --build-arg INSTALLER_BASE_IMAGE=ubuntu \
    --build-arg INSTALLER_BASE_TAG=24.04 \
    --build-arg BASE_IMAGE=quay.io/toolbx/ubuntu-toolbox \
    --build-arg BASE_TAG=24.04 \
    -t localhost/client-toolbox:"$ONEC_VERSION" \
    -t localhost/client-toolbox:latest \
    -f client-toolbox/Containerfile \
    "${last_args[@]}"

echo "=== Build complete: client-toolbox:$ONEC_VERSION ==="

if [ "${PUSH}" = 'true' ]; then
    if [ -z "${DOCKER_REGISTRY_URL}" ]; then
        echo "ERROR: DOCKER_REGISTRY_URL must be set when PUSH=true"
        exit 1
    fi
    echo "=== Pushing client-toolbox to ${DOCKER_REGISTRY_URL} ==="
    docker tag localhost/client-toolbox:"$ONEC_VERSION" "$DOCKER_REGISTRY_URL/client-toolbox:$ONEC_VERSION"
    docker tag localhost/client-toolbox:latest             "$DOCKER_REGISTRY_URL/client-toolbox:latest"
    docker push "$DOCKER_REGISTRY_URL/client-toolbox:$ONEC_VERSION"
    docker push "$DOCKER_REGISTRY_URL/client-toolbox:latest"
    echo "=== Push complete ==="
else
    echo "=== Skipping push (set PUSH=true to enable) ==="
fi
