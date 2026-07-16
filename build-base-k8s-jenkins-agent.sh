#!/usr/bin/env bash
set -eo pipefail

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

export ONEC_VERSION="${ONEC_VERSION:-8.5.1.1343}"
export YARD_VERSION="${YARD_VERSION:-1.9.2}"
export ONESCRIPT_VERSION="${ONESCRIPT_VERSION:-2.1.0}"

./build-installer.sh

echo "=== onec-client ==="
if [ -f secrets.env ]; then
  buildah build \
    --secret=id=secrets_env,src=secrets.env \
    --build-arg "INSTALLER_IMAGE=localhost/onec-installer:$YARD_VERSION" \
    --build-arg "ONEC_VERSION=$ONEC_VERSION" \
    -t localhost/onec-client:"$ONEC_VERSION" \
    -t localhost/onec-client:local \
    -f client/Containerfile \
    "${last_args[@]}"
else
  echo "WARNING: secrets.env not found; build may fail without credentials"
  buildah build \
    --build-arg "INSTALLER_IMAGE=localhost/onec-installer:$YARD_VERSION" \
    --build-arg "ONEC_VERSION=$ONEC_VERSION" \
    -t localhost/onec-client:"$ONEC_VERSION" \
    -t localhost/onec-client:local \
    -f client/Containerfile \
    "${last_args[@]}"
fi

echo "=== onec-client-s6 ==="
buildah build \
    --build-arg "BASE_IMAGE=localhost/onec-client:$ONEC_VERSION" \
    -t localhost/onec-client-s6:"$ONEC_VERSION" \
    -t localhost/onec-client-s6:local \
    -f s6-overlay/Containerfile \
    "${last_args[@]}"

echo "=== onec-client-vnc ==="
buildah build \
    --build-arg "BASE_IMAGE=localhost/onec-client-s6:$ONEC_VERSION" \
    -t localhost/onec-client-vnc:"$ONEC_VERSION" \
    -t localhost/onec-client-vnc:local \
    -f client-vnc/Containerfile \
    "${last_args[@]}"

echo "=== onec-client-vnc-oscript ==="
buildah build \
    --build-arg "BASE_IMAGE=localhost/onec-client-vnc:$ONEC_VERSION" \
    --build-arg "ONESCRIPT_VERSION=$ONESCRIPT_VERSION" \
    -t localhost/onec-client-vnc-oscript:"$ONEC_VERSION" \
    -t localhost/onec-client-vnc-oscript:local \
    -f oscript/Containerfile \
    "${last_args[@]}"

echo "=== onec-client-vnc-oscript-jdk ==="
buildah build \
    --build-arg "BASE_IMAGE=localhost/onec-client-vnc-oscript:$ONEC_VERSION" \
    -t localhost/onec-client-vnc-oscript-jdk:"$ONEC_VERSION" \
    -t localhost/onec-client-vnc-oscript-jdk:local \
    -f jdk/Containerfile \
    "${last_args[@]}"

echo "=== onec-client-vnc-oscript-jdk-testutils ==="
buildah build \
    --build-arg "BASE_IMAGE=localhost/onec-client-vnc-oscript-jdk:$ONEC_VERSION" \
    --build-arg "TEST_UTILS_EXTRA_PACKAGES=$TEST_UTILS_EXTRA_PACKAGES" \
    -t localhost/onec-client-vnc-oscript-jdk-testutils:"$ONEC_VERSION" \
    -t localhost/onec-client-vnc-oscript-jdk-testutils:local \
    -f test-utils/Containerfile \
    "${last_args[@]}"

echo "=== base-jenkins-agent ==="
buildah build \
    --build-arg "BASE_IMAGE=localhost/onec-client-vnc-oscript-jdk-testutils:$ONEC_VERSION" \
    -t localhost/base-jenkins-agent:"$ONEC_VERSION" \
    -t localhost/base-jenkins-agent:local \
    -f k8s-jenkins-agent/Containerfile \
    "${last_args[@]}"

if [[ "$PUSH" = "true" && -n "$CONTAINER_REGISTRY_URL" ]]; then
    echo "=== Публикация ==="
    buildah push localhost/onec-client:"$ONEC_VERSION" "$CONTAINER_REGISTRY_URL/onec-client:$ONEC_VERSION"
    buildah push localhost/onec-client-s6:"$ONEC_VERSION" "$CONTAINER_REGISTRY_URL/onec-client-s6:$ONEC_VERSION"
    buildah push localhost/onec-client-vnc:"$ONEC_VERSION" "$CONTAINER_REGISTRY_URL/onec-client-vnc:$ONEC_VERSION"
    if [[ "$PUSH_AGENT" != "false" ]]; then
        buildah push localhost/base-jenkins-agent:"$ONEC_VERSION" "$CONTAINER_REGISTRY_URL/base-jenkins-agent:$ONEC_VERSION"
    fi
else
    echo "=== Публикация пропущена (PUSH=true для включения) ==="
fi
