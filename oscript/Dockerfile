ARG BASE_IMAGE=debian
ARG BASE_TAG=13-slim

FROM debian:13-slim AS oscript-installer

ARG OVM_REPOSITORY_OWNER=oscript-library
ARG OVM_VERSION=1.6.2
ARG ONESCRIPT_VERSION=stable

ENV OVM_INSTALL_PATH=/opt/ovm
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    mono-runtime \
    ca-certificates-mono \
    libmono-i18n4.0-all \
    libmono-system-runtime-serialization4.0-cil
  cert-sync /etc/ssl/certs/ca-certificates.crt
  curl -L -o ovm.exe "https://github.com/${OVM_REPOSITORY_OWNER}/ovm/releases/download/v${OVM_VERSION}/ovm.exe"
  mkdir -m 755 -p "${OVM_INSTALL_PATH}"
  mv ovm.exe "${OVM_INSTALL_PATH}"
  printf '%s\n' '#!/usr/bin/env sh' "mono ${OVM_INSTALL_PATH}/ovm.exe \"\$@\"" > /usr/local/bin/ovm
  chmod +x /usr/local/bin/ovm
EOF

RUN <<EOF
  set -eux
  export HOME=/root
  ovm use --install "${ONESCRIPT_VERSION}"
  rm -f "${OVM_INSTALL_PATH}/ovm.exe" /usr/local/bin/ovm
EOF

FROM ${BASE_IMAGE}:${BASE_TAG}

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
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
ENV OVM_OSCRIPTBIN=$OVM_INSTALL_PATH/current/bin
ENV PATH="$OVM_OSCRIPTBIN:$PATH"

ARG ONESCRIPT_PACKAGES=""
RUN <<EOF
  set -eux
  opm install opm
  opm update --all
  if [ -n "${ONESCRIPT_PACKAGES}" ]; then opm install ${ONESCRIPT_PACKAGES}; fi
EOF

COPY ./oscript/docker-entrypoint.sh /
RUN <<EOF
  set -eux
  chmod 755 /docker-entrypoint.sh
  chmod +x /docker-entrypoint.sh
EOF

ENTRYPOINT ["/docker-entrypoint.sh"]
