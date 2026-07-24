ARG BASE_IMAGE

FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Dima Ovcharenko <d.ovcharenko90@gmail.com>, Korus Consulting LLC, \
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
  apt-mark hold iptables
  env DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
      xz-utils
EOF

# Install s6-overlay v3
ARG S6_OVERLAY_VERSION
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
  rm -f /tmp/s6-overlay-*.tar.xz
EOF

ENTRYPOINT ["/init"]
