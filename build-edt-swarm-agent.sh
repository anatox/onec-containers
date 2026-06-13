#!/usr/bin/env bash
set -eo pipefail

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

export EDT_VERSION="${EDT_VERSION:-2026.1.2}"

./build-edt.sh

echo "=== edt-s6 ==="
buildah build \
    --build-arg "BASE_IMAGE=localhost/edt:$EDT_VERSION" \
    -t localhost/edt-s6:"$EDT_VERSION" \
    -t localhost/edt-s6:local \
    -f s6-overlay/Containerfile \
    "${last_args[@]}"

echo "=== edt-agent ==="
buildah build \
    --build-arg "BASE_IMAGE=localhost/edt-s6:$EDT_VERSION" \
    -t localhost/edt-agent:"$EDT_VERSION" \
    -t localhost/edt-agent:local \
    -f swarm-jenkins-agent/Containerfile \
    "${last_args[@]}"

if [ "${PUSH}" = 'true' ]; then
    if [ -z "${CONTAINER_REGISTRY_URL}" ]; then
        echo "ОШИБКА: CONTAINER_REGISTRY_URL должен быть задан при PUSH=true"
        exit 1
    fi
    echo "=== Публикация ==="
    buildah push localhost/edt-s6:"$EDT_VERSION" "$CONTAINER_REGISTRY_URL/edt-s6:$EDT_VERSION"
    buildah push localhost/edt-agent:"$EDT_VERSION" "$CONTAINER_REGISTRY_URL/edt-agent:$EDT_VERSION"
else
    echo "=== Публикация пропущена (PUSH=true для включения) ==="
fi
