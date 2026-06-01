ARG BASE_IMAGE
ARG BASE_TAG

# BASE_IMAGE must contain s6-overlay
FROM ${BASE_IMAGE}:${BASE_TAG}

LABEL maintainer="Nikita Gryzlov <NikGryzlov@1bit.com>, FirstBit"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl \
    git \
    locales \
    openssh-client \
    wget
  curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git-lfs
  locale-gen ru_RU.UTF-8
EOF

ENV LANG=ru_RU.UTF-8

# add services to s6-overlay
COPY ./swarm-jenkins-agent/configs/rootfs-v3/ /

ENTRYPOINT ["/init"]
