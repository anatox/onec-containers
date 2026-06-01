ARG DOCKER_REGISTRY_URL=localhost
# Для EDT 2025.x ОБЯЗАТЕЛЬНО используем Java 17
ARG OPENJDK_VERSION=17
ARG BASE_IMAGE=eclipse-temurin
ARG BASE_TAG=${OPENJDK_VERSION}-jdk-noble
ARG INSTALLER_BASE_IMAGE=${BASE_IMAGE}
ARG INSTALLER_BASE_TAG=${BASE_TAG}

FROM ${DOCKER_REGISTRY_URL:+"$DOCKER_REGISTRY_URL"/}oscript-downloader:latest AS downloader

# Копирование скрипта скачивания и локальных дистрибутивов
COPY --chmod=755 ./scripts/download_yard.sh /download.sh
COPY ./distr /distr

# Скачивание дистрибутива 1С с использованием вынесенного скрипта
ARG ONEC_USERNAME
ARG ONEC_PASSWORD
ARG EDT_VERSION=2025.2.6

WORKDIR /tmp

# Установка необходимых пакетов и генерация локали
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  apt-get install -y \
          locales \
          p7zip-rar \
          p7zip-full
  locale-gen ru_RU.UTF-8
EOF

# Установка переменных окружения для корректной работы локали
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

RUN --mount=type=cache,target=/var/cache/yard,sharing=locked <<EOF
  set -eux
  /download.sh "$ONEC_USERNAME" "$ONEC_PASSWORD" "$EDT_VERSION" "edt"
  mkdir -p "/tmp/distr/DevelopmentTools10/${EDT_VERSION}"
  cp -r "/var/cache/yard/DevelopmentTools10/${EDT_VERSION}"/* "/tmp/distr/DevelopmentTools10/${EDT_VERSION}"/
EOF

FROM ${INSTALLER_BASE_IMAGE}:${INSTALLER_BASE_TAG} AS installer

LABEL maintainer="Nikita Gryzlov <NikGryzlov@1bit.com>, FirstBit"

ARG EDT_VERSION=2025.2.6

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    curl \
    libgtk-3-0t64 \
    locales \
    libc-bin \
    coreutils
  locale-gen ru_RU.UTF-8
  printf '#!/bin/sh\nif [ "$1" = "LONG_BIT" ]; then echo "64"; else echo "unknown"; fi' > /usr/local/bin/getconf
  chmod +x /usr/local/bin/getconf
EOF

# Install EDT
COPY --from=downloader /tmp/distr /tmp/distr
RUN <<EOF
  set -eux
  DISTR_PATH="/tmp/distr/DevelopmentTools10/${EDT_VERSION}"
  cd "$DISTR_PATH"
  chmod -R +x .
  ./1ce-installer-cli install all --ignore-hardware-checks --ignore-signature-warnings
  if [ -n "$(find /opt/1C/1CE -name ring)" ]; then
    ln -s $(dirname $(find /opt/1C/1CE -name ring)) /opt/1C/1CE/components/1c-enterprise-ring
  fi
  if [ -n "$(find /opt/1C/1CE -name 1cedtcli)" ]; then
    ln -s $(dirname $(find /opt/1C/1CE -name 1cedtcli)) /opt/1C/1CE/components/1cedtcli
  fi
  AXIOM_JDK=$(find /opt/1C/1CE/components -maxdepth 1 -name 'axiom-jdk-full-*' -type d | sort -V | tail -1)
  if [ -n "$AXIOM_JDK" ]; then
    ln -s "$AXIOM_JDK" /opt/1C/1CE/components/axiom-jdk
  fi
  rm -rf /tmp/*
  rm /usr/local/bin/getconf
EOF

FROM ${BASE_IMAGE}:${BASE_TAG}

LABEL maintainer="Nikita Gryzlov <NikGryzlov@1bit.com>, FirstBit"

WORKDIR /tmp

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    curl \
    libgtk-3-0t64 \
    locales \
    libxtst6
  locale-gen ru_RU.UTF-8
EOF

# Установка переменных окружения для корректной работы локали
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

# Copy EDT
COPY --from=installer /opt/1C/1CE /opt/1C/1CE

COPY --from=installer /etc/1C/1CE /etc/1C/1CE
COPY --from=installer /usr/share/applications /usr/share/applications

ENV JAVA_HOME=/opt/1C/1CE/components/axiom-jdk
ENV PATH="$JAVA_HOME/bin:/opt/1C/1CE/components/1cedtcli:$PATH"

RUN <<EOF
  set -eux
  find /opt/1C/1CE/components/1c-edt-start-* -maxdepth 1 -name 1cedtstart -type f -exec ln -sf {} /usr/local/bin/1cedtstart \;
  find /opt/1C/1CE/components/1c-edt-* -maxdepth 1 -name 1cedtcli -type f -exec ln -sf {} /usr/local/bin/1cedtcli \;
  find /opt/1C/1CE -name ring -type f -exec ln -sf {} /usr/local/bin/ring \;
  sed -i 's|^\(Exec=/opt/1C/1CE/components/[^/][^/]*/1cedtstart\)\(/opt/1C/1CE/components/[^/][^/]*/1cedtstart\)|\1|' "/usr/share/applications/com._1c.installer.1CEDT Start.desktop"
  sed -i '/^Path=/d' /usr/share/applications/com._1c.installer.*.desktop
EOF
