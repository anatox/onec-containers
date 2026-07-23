ARG BASE_IMAGE=ubuntu:26.04

FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Iosif Pravets <i@pravets.ru>, \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG DEBUG_TRACE

ARG EXECUTOR_VERSION

WORKDIR /tmp

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    locales \
    ca-certificates \
    curl
  locale-gen ru_RU.UTF-8
EOF

ENV LANG=ru_RU.UTF-8

RUN --mount=type=secret,id=dev1c_executor_api_key <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    unzip
  key="$(cat /run/secrets/dev1c_executor_api_key)"
  if [ -z "$key" ]; then
    echo "::error::Не задано значение DEV1C_EXECUTOR_API_KEY"
    exit 1
  fi
  curl -sSL --fail \
    -H "X-Developer-1c-Api:$key" \
    -o executor.zip \
    https://developer.1c.ru/applications/Console/api/v1/download/executor/${EXECUTOR_VERSION}/linux || {
    echo "::error::Не удалось скачать дистрибутив Executor ${EXECUTOR_VERSION} — проверьте ключ DEV1C_EXECUTOR_API_KEY или доступность developer.1c.ru"
    exit 1
  }
  unzip executor.zip
  rm executor.zip
  mkdir -p /opt/1C/executor
  cp -R ./* /opt/1C/executor
  rm -rf /tmp/*
  apt-get purge -y unzip
EOF

ENV PATH="/opt/1C/executor:$PATH"
ENTRYPOINT ["/opt/1C/executor/executor"]
