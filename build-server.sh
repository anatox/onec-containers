#!/usr/bin/env bash
set -eo pipefail

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

export ONEC_VERSION="${ONEC_VERSION:-8.5.1.1343}"
export YARD_VERSION="${YARD_VERSION:-1.9.2}"

./build-installer.sh

echo "=== onec-server ==="
buildah build \
    --secret=id=onec_username,env=ONEC_USERNAME \
    --secret=id=onec_password,env=ONEC_PASSWORD \
    --build-arg "INSTALLER_IMAGE=localhost/onec-installer:$YARD_VERSION" \
    --build-arg "ONEC_VERSION=$ONEC_VERSION" \
    -t localhost/onec-server:"$ONEC_VERSION" \
    -t localhost/onec-server:local \
    -f server/Containerfile \
    "${last_args[@]}"

if [ "${PUSH}" = 'true' ]; then
    if [ -z "${CONTAINER_REGISTRY_URL}" ]; then
        echo "ОШИБКА: CONTAINER_REGISTRY_URL должен быть задан при PUSH=true"
        exit 1
    fi
    echo "=== Публикация onec-server ==="
    buildah push localhost/onec-server:"$ONEC_VERSION" "$CONTAINER_REGISTRY_URL/onec-server:$ONEC_VERSION"
else
    echo "=== Публикация пропущена (PUSH=true для включения) ==="
fi
