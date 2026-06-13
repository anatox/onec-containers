#!/usr/bin/env bash
set -eo pipefail

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

export ONESCRIPT_VERSION="${ONESCRIPT_VERSION:-2.0.2}"
export YARD_VERSION="${YARD_VERSION:-1.9.2}"

echo "=== oscript ==="
buildah build \
    --build-arg BASE_IMAGE=ubuntu:26.04 \
    --build-arg "ONESCRIPT_VERSION=$ONESCRIPT_VERSION" \
    -t localhost/oscript:"$ONESCRIPT_VERSION" \
    -t localhost/oscript:local \
    -f oscript/Containerfile \
    "${last_args[@]}"

echo "=== onec-installer ==="
buildah build \
    --build-arg BASE_IMAGE=localhost/oscript:"$ONESCRIPT_VERSION" \
    --build-arg "YARD_VERSION=$YARD_VERSION" \
    -t localhost/onec-installer:"$YARD_VERSION" \
    -t localhost/onec-installer:local \
    -f installer/Containerfile \
    "${last_args[@]}"

if [ "${PUSH}" = 'true' ]; then
    if [ -z "${CONTAINER_REGISTRY_URL}" ]; then
        echo "ОШИБКА: CONTAINER_REGISTRY_URL должен быть задан при PUSH=true"
        exit 1
    fi
    echo "=== Публикация onec-installer ==="
    buildah push localhost/oscript:"$ONESCRIPT_VERSION" "$CONTAINER_REGISTRY_URL/oscript:$ONESCRIPT_VERSION"
    buildah push localhost/onec-installer:"$YARD_VERSION" "$CONTAINER_REGISTRY_URL/onec-installer:$YARD_VERSION"
else
    echo "=== Публикация пропущена (PUSH=true для включения) ==="
fi
