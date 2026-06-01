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
  /download.sh "$ONEC_USERNAME" "$ONEC_PASSWORD" "$ONEC_VERSION" "server"
  ONEC_MAJOR_VER=$(echo "$ONEC_VERSION" | cut -d'.' -f1,2 | tr -d '.')
  mkdir -p "/tmp/distr/Platform${ONEC_MAJOR_VER}/${ONEC_VERSION}"
  cp -r "/var/cache/yard/Platform${ONEC_MAJOR_VER}/${ONEC_VERSION}"/* "/tmp/distr/Platform${ONEC_MAJOR_VER}/${ONEC_VERSION}"/
EOF

# Начало основной стадии сборки
FROM ubuntu:24.04 AS installer

# Копируем скрипты и файлы установки
ARG ONEC_VERSION
ARG gosu_ver=1.11
ARG nls_enabled=false
ENV installer_type=server_crs
ENV nls=$nls_enabled


# Установка зависимостей и настройка локали
RUN <<EOF
  set -eux
  apt-get update
  apt-get install -yq \
    procps \
    tzdata \
    debconf-utils \
    curl \
    fontconfig \
    unixodbc \
    libgsf-1-114 \
    keyboard-configuration
  dpkg-reconfigure -f noninteractive tzdata
  dpkg-reconfigure -f noninteractive keyboard-configuration
  export LANG=ru_RU.UTF-8
EOF

COPY ./scripts/install_new.sh /install.sh
COPY --from=downloader /tmp/distr /tmp/distr
RUN <<EOF
  set -eux
  chmod +x /install.sh
  sync
  /install.sh
EOF

# Создание символической ссылки на текущую директорию 1C
COPY ./scripts/create-symlink-to-current-1cv8.sh /create-symlink-to-current-1cv8.sh
RUN <<EOF
  set -eux
  chmod +x /create-symlink-to-current-1cv8.sh
  /create-symlink-to-current-1cv8.sh
  rm /create-symlink-to-current-1cv8.sh
EOF

# Установка gosu
ADD https://github.com/tianon/gosu/releases/download/$gosu_ver/gosu-amd64 /bin/gosu
RUN chmod +x /bin/gosu

# Переход к финальному образу
FROM debian:bookworm-slim
LABEL maintainer="Anton Kvashenkin <anton.jugatsu@gmail.com> (@jugatsu)"

# Создание пользователя и установка локали
ARG onec_uid="999"
ARG onec_gid="999"
COPY --from=installer /opt/1cv8 /opt/1cv8
COPY --from=installer /bin/gosu /bin/gosu
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      locales
  locale-gen ru_RU.UTF-8
EOF
ENV LANG=ru_RU.UTF-8

# Настройка группы и пользователя
RUN <<EOF
  set -eux
  groupadd -r grp1cv8 --gid=$onec_gid
  useradd -r -g grp1cv8 --uid=$onec_uid --home-dir=/home/usr1cv8 --shell=/bin/bash usr1cv8
  mkdir -p /home/usr1cv8/.1cv8
  chown -R usr1cv8:grp1cv8 /home/usr1cv8
EOF

VOLUME /home/usr1cv8/.1cv8

# Установка точки входа
COPY ./crs/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN ln -s usr/local/bin/docker-entrypoint.sh /  # backwards compat
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Настройка точки входа и экспонирование портов
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
EXPOSE 1542
CMD ["crserver"]
