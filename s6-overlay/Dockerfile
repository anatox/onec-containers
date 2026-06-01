ARG BASE_IMAGE=debian
ARG BASE_TAG=bookworm-slim

FROM ${BASE_IMAGE}:${BASE_TAG}

LABEL maintainer="Dima Ovcharenko <d.ovcharenko90@gmail.com>, Korus Consulting LLC"

USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  apt-mark hold iptables
  env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      xz-utils
EOF

# Install s6-overlay v3
ARG S6_OVERLAY_VERSION=3.2.2.0
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN <<EOF
  set -eux
  tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
  rm -f /tmp/s6-overlay-*.tar.xz
EOF

ENTRYPOINT ["/init"]
