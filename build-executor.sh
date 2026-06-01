#!/usr/bin/env bash
set -eo pipefail


last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

# Проверяем, что переменная окружения установлена
if [ -z "$DEV1C_EXECUTOR_API_KEY" ]; then
    echo "Переменная среды DEV1C_EXECUTOR_API_KEY не установлена."
    exit 1
fi

# Записываем значение переменной в файл
umask 077
echo -n "$DEV1C_EXECUTOR_API_KEY" > /tmp/dev1c_executor_api_key.txt
echo "Ключ успешно записан в /tmp/dev1c_executor_api_key.txt"

executor_version="$EXECUTOR_VERSION"

docker build \
    --secret id=dev1c_executor_api_key,src=/tmp/dev1c_executor_api_key.txt \
    --pull \
    --build-arg "EXECUTOR_VERSION=$EXECUTOR_VERSION" \
    -t localhost/executor:"$executor_version" \
    -f "executor/Containerfile" \
    "${last_args[@]}"

shred -fzu "/tmp/dev1c_executor_api_key.txt" || true

if [[ "$PUSH" = "true" && -n "$DOCKER_REGISTRY_URL" ]]; then
    docker tag localhost/executor:"$executor_version" "$DOCKER_REGISTRY_URL/executor:$executor_version"
    docker push "$DOCKER_REGISTRY_URL/executor:$executor_version"
else
    echo "PUSH not enabled or DOCKER_REGISTRY_URL not set, skipping push."
fi
