ARG BASE_IMAGE=ubuntu:26.04
ARG INSTALLER_IMAGE=localhost/onec-installer:local

FROM ${INSTALLER_IMAGE} AS installer

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBUG_TRACE
ARG ONEC_VERSION
ARG GOSU_VERSION
ARG NLS_ENABLED=0

# Копирование локальных дистрибутивов
COPY ./distr /distr

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  apt-get install -yq --no-install-recommends \
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
  if [ -d /usr/share/applications ]; then find /usr/share/applications -maxdepth 1 -name '*.desktop' -delete; fi
EOF

# Установка gosu
ADD https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64 /tmp/gosu-amd64
ADD https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/SHA256SUMS /tmp/SHA256SUMS

# hadolint ignore=DL3003
RUN <<'EOF'
  (cd /tmp && grep 'gosu-amd64$' SHA256SUMS | sha256sum -c -)
  cp /tmp/gosu-amd64 /bin/gosu && chmod 755 /bin/gosu
  rm -f /tmp/gosu-amd64 /tmp/SHA256SUMS
EOF

# Начало основной стадии сборки
RUN --mount=type=cache,id=distr-cache,target=/var/cache/yard,sharing=locked \
    --mount=type=secret,id=onec_username \
    --mount=type=secret,id=onec_password <<'EOF'
  ONEC_USERNAME="$(cat /run/secrets/onec_username)"
  ONEC_PASSWORD="$(cat /run/secrets/onec_password)"
  export ONEC_USERNAME ONEC_PASSWORD
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  [ "${NLS_ENABLED:-0}" -ne 0 ] && NLS_ARGS=(nls) || NLS_ARGS=()
  onec-install server_crs "$ONEC_VERSION" "${NLS_ARGS[@]}"
EOF

# Переход к финальному образу
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Anton Kvashenkin <anton.jugatsu@gmail.com> (@jugatsu), \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBUG_TRACE
ARG onec_uid="999"
ARG onec_gid="999"
COPY --from=installer /opt/1cv8 /opt/1cv8
COPY --from=installer /bin/gosu /bin/gosu

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
      locales
  locale-gen ru_RU.UTF-8
EOF

# Установка переменных окружения для корректной работы локали
ENV LANG=ru_RU.UTF-8

RUN <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  getent group grp1cv8 >/dev/null || groupadd -r grp1cv8 --gid=$onec_gid
  getent passwd usr1cv8 >/dev/null || useradd -r -g grp1cv8 --uid=$onec_uid --home-dir=/home/usr1cv8 --shell=/bin/bash usr1cv8
  mkdir -p /home/usr1cv8/.1cv8
  chown -R usr1cv8:grp1cv8 /home/usr1cv8
EOF

VOLUME /home/usr1cv8/.1cv8

COPY --chmod=755 ./crs/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

EXPOSE 1542
CMD ["crserver"]
