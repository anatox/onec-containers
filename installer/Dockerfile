ARG BASE_IMAGE=localhost/oscript:local

FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG YARD_VERSION

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    7zip
  opm install \
    yard@${YARD_VERSION}
EOF

# Копируем скрипты установки
COPY --chmod=755 ./scripts/installer /opt/onec-installer
ENV PATH="$PATH:/opt/onec-installer/bin"
