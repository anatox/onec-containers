#!/usr/bin/env bash
set -eo pipefail

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

export ONEC_VERSION="${ONEC_VERSION:-8.5.1.1343}"
export YARD_VERSION="${YARD_VERSION:-1.9.2}"
export EDT_VERSION="${EDT_VERSION:-2026.1.2}"

./build-installer.sh

echo "=== edt-toolbox (base) ==="
buildah build \
    --secret=id=onec_username,env=ONEC_USERNAME \
    --secret=id=onec_password,env=ONEC_PASSWORD \
  --build-arg "INSTALLER_IMAGE=localhost/onec-installer:$YARD_VERSION" \
  --build-arg "EDT_VERSION=$EDT_VERSION" \
  -t localhost/edt-toolbox:"${EDT_VERSION}-base" \
  -t localhost/edt-toolbox:local \
    -f edt-toolbox/Containerfile \
    "${last_args[@]}"

EDT_CLIENT_TAG="${EDT_VERSION}-client${ONEC_VERSION}"

echo "=== edt-toolbox (client-toolbox) ==="
buildah build \
    --secret=id=onec_username,env=ONEC_USERNAME \
    --secret=id=onec_password,env=ONEC_PASSWORD \
    --build-arg "INSTALLER_IMAGE=localhost/onec-installer:$YARD_VERSION" \
    --build-arg "ONEC_VERSION=$ONEC_VERSION" \
    --build-arg "BASE_IMAGE=localhost/edt-toolbox:${EDT_VERSION}-base" \
    -t localhost/edt-toolbox:"$EDT_CLIENT_TAG" \
    -t localhost/edt-toolbox:local \
    -f client-toolbox/Containerfile \
    "${last_args[@]}"

echo "=== Сборка завершена: edt-toolbox:$EDT_CLIENT_TAG ==="

if [ "${PUSH}" = 'true' ]; then
    if [ -z "${CONTAINER_REGISTRY_URL}" ]; then
        echo "ОШИБКА: CONTAINER_REGISTRY_URL должен быть задан при PUSH=true"
        exit 1
    fi
    echo "=== Публикация edt-toolbox ==="
    buildah push localhost/edt-toolbox:"$EDT_CLIENT_TAG" "$CONTAINER_REGISTRY_URL/edt-toolbox:$EDT_CLIENT_TAG"
else
    echo "=== Публикация пропущена (PUSH=true для включения) ==="
fi
