ARG BASE_IMAGE

FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Nikita Gryzlov <NikGryzlov@1bit.com>, FirstBit, \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG DEBUG_TRACE

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    curl \
    git \
    git-lfs \
    locales \
    openssh-client \
    wget
  locale-gen ru_RU.UTF-8
EOF

ENV LANG=ru_RU.UTF-8

# add services to s6-overlay
COPY ./swarm-jenkins-agent/configs/rootfs-v3/ /

ENTRYPOINT ["/init"]
