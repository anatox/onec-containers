ARG BASE_IMAGE=ubuntu:26.04

FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Nikita Gryzlov <NikGryzlov@1bit.com>, FirstBit, \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG DEBUG_TRACE

# Install OpenJDK
ARG OPENJDK_VERSION

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    git \
    gnupg \
    dirmngr \
    locales \
    software-properties-common \
    wget
  update-ca-certificates
  mkdir -p /etc/apt/keyrings
  echo "Acquire::https::packages.adoptium.net::Verify-Peer \"false\";" | tee /etc/apt/apt.conf.d/adoptium-no-check-cert
  wget --no-check-certificate --no-verbose -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg
  echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
  apt-get update -qq
  apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends temurin-${OPENJDK_VERSION}-jdk
  rm -f /etc/apt/apt.conf.d/adoptium-no-check-cert
  locale-gen ru_RU.UTF-8
EOF

# remove DST Root CA X3 cert if it exists
COPY --chmod=755 ./scripts/remove-dst-root-ca-x3.sh /remove-dst-root-ca-x3.sh
RUN <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  /remove-dst-root-ca-x3.sh
  rm /remove-dst-root-ca-x3.sh
EOF

ENV LANG=ru_RU.UTF-8
