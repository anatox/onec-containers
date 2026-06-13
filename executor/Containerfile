ARG BASE_IMAGE=ubuntu
ARG BASE_TAG=24.04
FROM ${BASE_IMAGE}:${BASE_TAG}

LABEL maintainer="i@pravets.ru"
LABEL author="Iosif Pravets"

ARG EXECUTOR_VERSION

WORKDIR /tmp

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    locales \
    ca-certificates \
    curl \
    unzip
  locale-gen ru_RU.UTF-8
EOF

ENV LANG=ru_RU.UTF-8

# Install Executor (используем BuildKit secret)
RUN --mount=type=secret,id=dev1c_executor_api_key <<EOF
  set -eux
  curl -sSL --fail \
    -H "X-Developer-1c-Api:$(cat /run/secrets/dev1c_executor_api_key)" \
    -o executor.zip \
    https://developer.1c.ru/applications/Console/api/v1/download/executor/${EXECUTOR_VERSION}/linux
  unzip executor.zip
  rm executor.zip
  mkdir -p /opt/1C/executor
  cp -R * /opt/1C/executor
# cleanup
  rm -rf /tmp/*
  apt purge -y unzip
EOF

ENV PATH="/opt/1C/executor:$PATH"
ENTRYPOINT ["/opt/1C/executor/executor"]