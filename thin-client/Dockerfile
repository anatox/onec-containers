ARG DOCKER_REGISTRY_URL=localhost
FROM ${DOCKER_REGISTRY_URL:+"$DOCKER_REGISTRY_URL"/}oscript-downloader:latest AS downloader

# Копирование скрипта скачивания и локальных дистрибутивов
COPY ./scripts/download_yard.sh /download.sh
COPY ./distr /distr
RUN chmod +x /download.sh

# Скачивание дистрибутива 1С с использованием вынесенного скрипта
ARG ONEC_USERNAME
ARG ONEC_PASSWORD
ARG ONEC_VERSION

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
  /download.sh "$ONEC_USERNAME" "$ONEC_PASSWORD" "$ONEC_VERSION" "thin-client"
  ONEC_MAJOR_VER=$(echo "$ONEC_VERSION" | cut -d'.' -f1,2 | tr -d '.')
  mkdir -p "/tmp/distr/Platform${ONEC_MAJOR_VER}/${ONEC_VERSION}"
  cp -r "/var/cache/yard/Platform${ONEC_MAJOR_VER}/${ONEC_VERSION}"/* "/tmp/distr/Platform${ONEC_MAJOR_VER}/${ONEC_VERSION}"/
EOF

# Начало основной стадии сборки
FROM ubuntu:18.04 AS base

# Копируем скрипты и файлы установки
ARG ONEC_VERSION
ARG gosu_ver=1.11
ARG nls_enabled=false
ENV nls=$nls_enabled
ENV installer_type=thin-client

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  chmod 777 -R /tmp
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libwebkitgtk-3.0-0
EOF

COPY ./scripts/install_new.sh /install.sh
COPY --from=downloader /tmp/distr /tmp/distr
RUN <<EOF
  set -eux
  chmod +x /install.sh
  sync
  /install.sh
EOF

# create symlink to current 1c:enterprise directory
COPY ./scripts/create-symlink-to-current-1cv8.sh /create-symlink-to-current-1cv8.sh
RUN <<EOF
  set -eux
  chmod +x /create-symlink-to-current-1cv8.sh
  /create-symlink-to-current-1cv8.sh
  rm /create-symlink-to-current-1cv8.sh
EOF

COPY ./configs/client/current/ /opt/1cv8/current/

FROM ubuntu:18.04
LABEL maintainer="Anton Kvashenkin <anton.jugatsu@gmail.com> (@jugatsu)"

ARG onec_uid="999"
ARG onec_gid="999"

COPY --from=base /opt /opt

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    locales \
    ca-certificates \
    libwebkitgtk-3.0-0 \
    ttf-mscorefonts-installer \
    libfontconfig1 \
    libgsf-1-114 \
    libglib2.0-0 \
    libodbc1 \
    libmagickwand-6.q16-3 \
    dbus-x11
  locale-gen ru_RU.UTF-8
EOF
ENV LANG=ru_RU.UTF-8

RUN <<EOF
  set -eux
  groupadd -r grp1cv8 --gid=$onec_gid
  useradd -r -g grp1cv8 --uid=$onec_uid --home-dir=/home/usr1cv8 --shell=/bin/bash usr1cv8
  mkdir -p /home/usr1cv8/.1cv8
  chown -R usr1cv8:grp1cv8 /home/usr1cv8
EOF

VOLUME /home/usr1cv8/.1cv8

USER usr1cv8

CMD ["/opt/1C/v8.3/x86_64/1cv8c"]
