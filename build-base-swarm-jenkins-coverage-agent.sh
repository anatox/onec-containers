#!/usr/bin/env bash
set -eo pipefail

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

export ONEC_VERSION="${ONEC_VERSION:-8.5.1.1343}"
export EDT_VERSION="${EDT_VERSION:-2026.1.2}"
export COVERAGE41C_VERSION="${COVERAGE41C_VERSION:-2.7.3}"

./build-edt.sh

export PUSH_AGENT='false'
./build-base-swarm-jenkins-agent.sh

echo "=== base-jenkins-coverage-agent ==="
buildah build \
    --build-arg "BASE_IMAGE=localhost/base-jenkins-agent:$ONEC_VERSION" \
    --build-arg "EDT_IMAGE=localhost/edt:$EDT_VERSION" \
    --build-arg "COVERAGE41C_VERSION=$COVERAGE41C_VERSION" \
    -t localhost/base-jenkins-coverage-agent:"$ONEC_VERSION" \
    -t localhost/base-jenkins-coverage-agent:local \
    -f coverage41C/Containerfile \
    "${last_args[@]}"

if [ "${PUSH}" = 'true' ]; then
    if [ -z "${CONTAINER_REGISTRY_URL}" ]; then
        echo "ОШИБКА: CONTAINER_REGISTRY_URL должен быть задан при PUSH=true"
        exit 1
    fi
    echo "=== Публикация ==="
    buildah push localhost/base-jenkins-coverage-agent:"$ONEC_VERSION" "$CONTAINER_REGISTRY_URL/base-jenkins-coverage-agent:$ONEC_VERSION"
else
    echo "=== Публикация пропущена (PUSH=true для включения) ==="
fi
