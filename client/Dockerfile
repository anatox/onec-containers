ARG BASE_IMAGE=ubuntu:26.04
ARG INSTALLER_IMAGE=localhost/onec-installer:local
ARG DEBUG_TRACE

FROM ${INSTALLER_IMAGE} AS installer

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBUG_TRACE
ARG ONEC_VERSION
ARG NLS_ENABLED=false

# Копирование локальных дистрибутивов
COPY distr /distr

# Установка gnupg и wget
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    gnupg \
    wget \
    ca-certificates
EOF

# Установка недостающих библиотек
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    libgtk-3-0t64 \
    libenchant-2-2 \
    libharfbuzz-icu0 \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    libsecret-1-0 \
    libsoup2.4-1 \
    libsqlite3-0 \
    libgl1 \
    libegl1 \
    libxrender1 \
    libxfixes3 \
    libxslt1.1 \
    libsm6 \
    geoclue-2.0
EOF

# Начало основной стадии сборки
RUN --mount=type=cache,id=distr-cache,target=/var/cache/yard,sharing=locked \
    --mount=type=secret,id=onec_username \
    --mount=type=secret,id=onec_password <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  ONEC_USERNAME="$(cat /run/secrets/onec_username)"
  ONEC_PASSWORD="$(cat /run/secrets/onec_password)"
  export ONEC_USERNAME ONEC_PASSWORD
  if [ -d /usr/share/applications ]; then find /usr/share/applications -maxdepth 1 -name '*.desktop' -delete; fi
  onec-install --nls="$NLS_ENABLED" client "$ONEC_VERSION"
EOF

COPY client/configs/current/ /opt/1cv8/current/

# Переход к финальному образу
FROM ${BASE_IMAGE} AS base

LABEL org.opencontainers.image.authors="Anton Kvashenkin <anton.jugatsu@gmail.com> (@jugatsu), \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBUG_TRACE

# Установка gnupg и wget
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    gnupg \
    wget \
    ca-certificates
EOF

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    locales \
    libgtk2.0-0t64 \
    libwebkit2gtk-4.1-0 \
    ttf-mscorefonts-installer \
    libfontconfig1 \
    libgsf-1-114 \
    libglib2.0-0 \
    libodbc2 \
    libmagickwand-7.q16-10 \
    dbus-x11 \
    libsm6 \
    libglu1-mesa
  locale-gen ru_RU.UTF-8
  if [ -d /usr/share/applications ]; then find /usr/share/applications -maxdepth 1 -name '*.desktop' -delete; fi
EOF

# Установка переменных окружения для корректной работы локали
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

COPY --from=installer /opt /opt
COPY --from=installer /usr/share/icons /usr/share/icons
COPY --from=installer /usr/share/applications /usr/share/applications


FROM base AS client

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBUG_TRACE
ARG onec_uid="999"
ARG onec_gid="999"

RUN <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  groupadd -r grp1cv8 --gid=$onec_gid
  useradd -r -g grp1cv8 --uid=$onec_uid --home-dir=/home/usr1cv8 --shell=/bin/bash usr1cv8
  mkdir -p /home/usr1cv8/.1cv8
  chown -R usr1cv8:grp1cv8 /home/usr1cv8
EOF

VOLUME /home/usr1cv8/.1cv8/

USER usr1cv8

CMD ["/opt/1C/v8.3/x86_64/1cv8"]
