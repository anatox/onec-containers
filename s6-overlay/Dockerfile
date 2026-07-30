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
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz.sha256 /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz.sha256 /tmp

# hadolint ignore=DL3003
RUN <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  (cd /tmp && sha256sum -c s6-overlay-*.sha256)
  tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
  tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
  rm -f /tmp/s6-overlay-*.tar.xz /tmp/s6-overlay-*.sha256
EOF

ENTRYPOINT ["/init"]
