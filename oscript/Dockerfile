ARG BASE_IMAGE=ubuntu:26.04

FROM debian:13-slim AS oscript-installer

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG DEBUG_TRACE

# Установка oscript с помощью ovm
ARG OVM_REPOSITORY_OWNER=oscript-library
ARG OVM_VERSION
ARG ONESCRIPT_VERSION
ENV OVM_INSTALL_PATH=/opt/ovm
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

ADD --chmod=755 "https://github.com/${OVM_REPOSITORY_OWNER}/ovm/releases/download/v${OVM_VERSION}/ovm.exe" ${OVM_INSTALL_PATH}/ovm.exe

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    ca-certificates \
    mono-runtime \
    ca-certificates-mono \
    libmono-i18n4.0-all \
    libmono-system-runtime-serialization4.0-cil
  cert-sync /etc/ssl/certs/ca-certificates.crt
  printf '%s\n' '#!/usr/bin/env sh' "mono ${OVM_INSTALL_PATH}/ovm.exe \"\$@\"" > /usr/local/bin/ovm
  chmod +x /usr/local/bin/ovm
EOF

RUN <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  export HOME=/root
  ovm use --install "${ONESCRIPT_VERSION}"
  rm -f "${OVM_INSTALL_PATH}/ovm.exe" /usr/local/bin/ovm
EOF

FROM ${BASE_IMAGE}

# hadolint ignore=DL3002
USER root

# Установка библиотек и локали
LABEL org.opencontainers.image.authors="Anton Kvashenkin <anton.jugatsu@gmail.com> (@jugatsu), \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG DEBUG_TRACE

# hadolint ignore=DL3002
USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    locales \
    libicu-dev \
    ca-certificates
  locale-gen ru_RU.UTF-8
EOF

ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8
ENV OVM_INSTALL_PATH=/opt/ovm
COPY --from=oscript-installer ${OVM_INSTALL_PATH} ${OVM_INSTALL_PATH}
ENV OSCRIPT_HOME=$OVM_INSTALL_PATH/current
ENV PATH="$OSCRIPT_HOME/bin:$PATH"

# Обновление и установка пакетов oscript
ARG ONESCRIPT_PACKAGES=""

RUN <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  opm install opm
  opm update --all
  if [ -n "${ONESCRIPT_PACKAGES}" ]; then opm install ${ONESCRIPT_PACKAGES}; fi
EOF

COPY --chmod=755 ./oscript/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
