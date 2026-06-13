#!/usr/bin/env bash
set -eo pipefail

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

export YARD_VERSION="${YARD_VERSION:-1.9.2}"
export EDT_VERSION="${EDT_VERSION:-2026.1.2}"

./build-installer.sh

echo "=== EDT ==="
buildah build \
    --secret=id=onec_username,env=ONEC_USERNAME \
    --secret=id=onec_password,env=ONEC_PASSWORD \
    --build-arg "INSTALLER_IMAGE=localhost/onec-installer:$YARD_VERSION" \
    --build-arg "EDT_VERSION=$EDT_VERSION" \
    -t localhost/edt:"$EDT_VERSION" \
    -t localhost/edt:local \
    -f edt/Containerfile \
    "${last_args[@]}"

if [ "${PUSH}" = 'true' ]; then
    if [ -z "${CONTAINER_REGISTRY_URL}" ]; then
        echo "ОШИБКА: CONTAINER_REGISTRY_URL должен быть задан при PUSH=true"
        exit 1
    fi
    echo "=== Публикация EDT ==="
    buildah push localhost/edt:"$EDT_VERSION" "$CONTAINER_REGISTRY_URL/edt:$EDT_VERSION"
else
    echo "=== Публикация пропущена (PUSH=true для включения) ==="
fi
