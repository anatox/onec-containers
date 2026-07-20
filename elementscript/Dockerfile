ARG BASE_IMAGE=ubuntu:26.04

FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Anatolii Sereda <3011745+anatox@users.noreply.github.com>"
LABEL author="Iosif Pravets"

ARG ELEMENTSCRIPT_VERSION

WORKDIR /tmp

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  set -eux
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    locales \
    ca-certificates \
    curl \
    unzip
  locale-gen ru_RU.UTF-8
EOF

ENV LANG=ru_RU.UTF-8

RUN --mount=type=secret,id=elementscript_download_token <<'EOF'
  set -eux
  curl -sSL --fail \
    -H "X-Developer-1c-Api:$(cat /run/secrets/elementscript_download_token)" \
    -o script.zip \
    https://developer.1c.ru/applications/Console/api/v1/download/elementscript/${ELEMENTSCRIPT_VERSION}/linux
  unzip script.zip
  rm script.zip
  mkdir -p /opt/1C/script
  cp -R * /opt/1C/script
  rm -rf /tmp/*
  apt-get purge -y unzip
EOF

ENV PATH="/opt/1C/script:$PATH"
ENTRYPOINT ["/opt/1C/script/executor"]
