ARG BASE_IMAGE=ubuntu:26.04
ARG INSTALLER_IMAGE=localhost/onec-installer:local
ARG EDT_VERSION

FROM ${INSTALLER_IMAGE} AS installer

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG DEBUG_TRACE

ARG EDT_VERSION

COPY ./distr /distr
COPY --chmod=755 ./scripts/install-edt-jdk.sh /install-edt-jdk.sh

# Установка JDK и библиотек для EDT
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  /install-edt-jdk.sh "$EDT_VERSION"

  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    curl \
    libgtk-3-0t64 \
    locales \
    libc-bin \
    coreutils
  locale-gen ru_RU.UTF-8
  if [ -d /usr/share/applications ]; then find /usr/share/applications -maxdepth 1 -name '*.desktop' -delete; fi
EOF

# Скачивание и установка EDT
RUN --mount=type=cache,id=distr-cache,target=/var/cache/yard,sharing=locked \
    --mount=type=secret,id=onec_username \
    --mount=type=secret,id=onec_password <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  ONEC_USERNAME="$(cat /run/secrets/onec_username)"
  ONEC_PASSWORD="$(cat /run/secrets/onec_password)"
  export ONEC_USERNAME ONEC_PASSWORD
  onec-install edt "$EDT_VERSION"
EOF

FROM ${BASE_IMAGE} AS final

LABEL org.opencontainers.image.authors="Nikita Gryzlov <NikGryzlov@1bit.com>, FirstBit, \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG DEBUG_TRACE
ARG EDT_VERSION

WORKDIR /tmp

COPY --chmod=755 ./scripts/install-edt-jdk.sh /install-edt-jdk.sh
COPY --chmod=755 ./scripts/install-edt-nginx.sh /install-edt-nginx.sh

# Установка JDK и библиотек для финального образа
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  /install-edt-jdk.sh "$EDT_VERSION"

  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    curl \
    libgtk-3-0t64 \
    locales \
    libxtst6
  locale-gen ru_RU.UTF-8
  if [ -d /usr/share/applications ]; then find /usr/share/applications -maxdepth 1 -name '*.desktop' -delete; fi
  /install-edt-nginx.sh
EOF

# Установка переменных окружения для корректной работы локали
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

# Copy EDT
COPY --from=installer /opt/1C/1CE /opt/1C/1CE
COPY --from=installer /etc/1C/1CE /etc/1C/1CE
COPY --from=installer /usr/share/applications /usr/share/applications

ENV JAVA_HOME=/opt/1C/1CE/components/jdk-current
ENV PATH="$JAVA_HOME/bin:/opt/1C/1CE/components/1c-edt-current:/opt/1C/1CE/components/1c-edt-start-current:$PATH"

FROM final AS toolbox

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBUG_TRACE

COPY --chmod=755 scripts/distrobox-shims.sh /distrobox-shims.sh

RUN <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  /distrobox-shims.sh
  rm /distrobox-shims.sh
EOF
