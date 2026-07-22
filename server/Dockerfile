ARG BASE_IMAGE=ubuntu:26.04
ARG INSTALLER_IMAGE=localhost/onec-installer:local

FROM ${INSTALLER_IMAGE} AS installer

ARG ONEC_VERSION
ARG GOSU_VERSION
ARG NLS_ENABLED=false

# Копирование локальных дистрибутивов
COPY ./distr /distr

# Установка зависимостей и настройка локали
RUN <<'EOF'
  set -euxo pipefail
  apt-get update -qq
  apt-get install -yq \
    procps \
    tzdata \
    debconf-utils \
    curl \
    fontconfig \
    unixodbc \
    ttf-mscorefonts-installer \
    libgsf-1-114 \
    keyboard-configuration
  dpkg-reconfigure -f noninteractive tzdata
  dpkg-reconfigure -f noninteractive keyboard-configuration
  apt-get install -yq geoclue-2.0 gstreamer1.0-plugins-bad
  export LANG=ru_RU.UTF-8
  if [ -d /usr/share/applications ]; then find /usr/share/applications -maxdepth 1 -name '*.desktop' -delete; fi
EOF

# Установка gosu
ADD --chmod=755 https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64 /bin/gosu

# Начало основной стадии сборки
RUN --mount=type=cache,id=distr-cache,target=/var/cache/yard,sharing=locked \
    --mount=type=secret,id=onec_username \
    --mount=type=secret,id=onec_password <<'EOF'
  set -euxo pipefail
  export ONEC_USERNAME="$(cat /run/secrets/onec_username)"
  export ONEC_PASSWORD="$(cat /run/secrets/onec_password)"
  onec-install --nls="$NLS_ENABLED" server "$ONEC_VERSION"
EOF

# Переход к финальному образу
FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.authors="Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

ARG onec_uid="999"
ARG onec_gid="999"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  set -euxo pipefail
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
      locales \
      iproute2 \
      imagemagick \
      fontconfig \
      ca-certificates
  locale-gen ru_RU.UTF-8
EOF
# Установка переменных окружения для корректной работы локали
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

COPY --from=installer /opt/1cv8 /opt/1cv8
COPY --from=installer /bin/gosu /bin/gosu

# Настройка группы и пользователя
RUN <<'EOF'
  set -euxo pipefail
  groupadd -r grp1cv8 --gid=$onec_gid
  useradd -r -g grp1cv8 --uid=$onec_uid --home-dir=/home/usr1cv8 --shell=/bin/bash usr1cv8
  mkdir -p /var/log/1C /home/usr1cv8/.1cv8/1C/1cv8/conf /opt/1cv8/current/conf
  chown -R usr1cv8:grp1cv8 /var/log/1C /home/usr1cv8
EOF

VOLUME /home/usr1cv8/.1cv8 /var/log/1C

# Копирование конфигурационных файлов
COPY ./server/logcfg.xml /home/usr1cv8/.1cv8/1C/1cv8/conf
COPY ./server/logcfg.xml /opt/1cv8/current/conf

# Установка точки входа и выполнение дополнительных настроек
COPY --chmod=755 ./server/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN ln -s usr/local/bin/entrypoint.sh /  # backwards compat
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  set -euxo pipefail
  apt-get update -qq
  apt-get install -yq procps
  chmod +x /opt/1cv8/current/ragent
EOF

# Настройка точки входа и экспонирование портов
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
EXPOSE 1540 1541 1545 1560
CMD ["ragent"]
