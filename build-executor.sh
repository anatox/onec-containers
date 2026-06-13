#!/usr/bin/env bash
set -eo pipefail

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

if [ -z "$DEV1C_EXECUTOR_API_KEY" ]; then
    echo "=== Переменная среды DEV1C_EXECUTOR_API_KEY не установлена."
    exit 1
fi

export EXECUTOR_VERSION="${EXECUTOR_VERSION:-3.0.2.2}"

buildah build \
    --secret id=dev1c_executor_api_key,env=DEV1C_EXECUTOR_API_KEY \
    --build-arg "EXECUTOR_VERSION=$EXECUTOR_VERSION" \
    -t localhost/executor:"$EXECUTOR_VERSION" \
    -t localhost/executor:local \
    -f "executor/Containerfile" \
    "${last_args[@]}"

if [[ "$PUSH" = "true" && -n "$CONTAINER_REGISTRY_URL" ]]; then
    buildah push localhost/executor:"$EXECUTOR_VERSION" "$CONTAINER_REGISTRY_URL/executor:$EXECUTOR_VERSION"
else
    echo "=== PUSH not enabled or CONTAINER_REGISTRY_URL not set, skipping push."
fi
