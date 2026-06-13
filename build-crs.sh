#!/usr/bin/env bash
set -eo pipefail

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

export ONEC_VERSION="${ONEC_VERSION:-8.5.1.1343}"
export YARD_VERSION="${YARD_VERSION:-1.9.2}"

./build-installer.sh

echo "=== crs ==="
buildah build \
    --secret=id=onec_username,env=ONEC_USERNAME \
    --secret=id=onec_password,env=ONEC_PASSWORD \
    --build-arg "INSTALLER_IMAGE=localhost/onec-installer:$YARD_VERSION" \
    --build-arg "ONEC_VERSION=$ONEC_VERSION" \
    -t localhost/crs:"$ONEC_VERSION" \
    -t localhost/crs:local \
    -f crs/Containerfile \
    "${last_args[@]}"

echo "=== crs-apache ==="
buildah build \
    --build-arg "BASE_IMAGE=localhost/crs:$ONEC_VERSION" \
    --build-arg "ONEC_VERSION=$ONEC_VERSION" \
    -t localhost/crs-apache:"$ONEC_VERSION" \
    -t localhost/crs-apache:local \
    -f crs-apache/Containerfile \
    "${last_args[@]}"

if [ "${PUSH}" = 'true' ]; then
    if [ -z "${CONTAINER_REGISTRY_URL}" ]; then
        echo "ОШИБКА: CONTAINER_REGISTRY_URL должен быть задан при PUSH=true"
        exit 1
    fi
    echo "=== Публикация crs ==="
    buildah push localhost/crs:"$ONEC_VERSION" "$CONTAINER_REGISTRY_URL/crs:$ONEC_VERSION"
    buildah push localhost/crs-apache:"$ONEC_VERSION" "$CONTAINER_REGISTRY_URL/crs-apache:$ONEC_VERSION"
else
    echo "=== Публикация пропущена (PUSH=true для включения) ==="
fi
