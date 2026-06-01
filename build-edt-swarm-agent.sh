#!/usr/bin/env bash
set -eo pipefail


last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

./build-edt.sh

docker build \
    --build-arg BASE_IMAGE=localhost/edt \
    --build-arg "BASE_TAG=$EDT_VERSION" \
    -t localhost/edt-s6:"$EDT_VERSION" \
    -f s6-overlay/Containerfile \
    "${last_args[@]}"

docker build \
    --build-arg BASE_IMAGE=localhost/edt-s6 \
    --build-arg "BASE_TAG=$EDT_VERSION" \
    -t localhost/edt-agent:"$EDT_VERSION" \
    -f swarm-jenkins-agent/Containerfile \
    "${last_args[@]}"

if [[ "$PUSH" = "true" && -n "$DOCKER_REGISTRY_URL" ]]; then
    docker tag localhost/edt-s6:"$EDT_VERSION" "$DOCKER_REGISTRY_URL/edt-s6:$EDT_VERSION"
    docker push "$DOCKER_REGISTRY_URL/edt-s6:$EDT_VERSION"
    docker tag localhost/edt-agent:"$EDT_VERSION" "$DOCKER_REGISTRY_URL/edt-agent:$EDT_VERSION"
    docker push "$DOCKER_REGISTRY_URL/edt-agent:$EDT_VERSION"
else
    echo "PUSH not enabled or DOCKER_REGISTRY_URL not set, skipping push."
fi
