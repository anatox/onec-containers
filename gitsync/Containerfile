ARG DOCKER_REGISTRY_URL=localhost
ARG ONEC_VERSION
FROM ${DOCKER_REGISTRY_URL:+"$DOCKER_REGISTRY_URL"/}onec-client:${ONEC_VERSION} AS base

FROM oscript:2.0.2
LABEL maintainer="Anton Kvashenkin <anton.jugatsu@gmail.com> (@jugatsu)"

ARG gitsync_ver=3.7.3

COPY --from=base /opt /opt

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  echo "deb http://http.debian.net/debian/ stretch main contrib non-free" > /etc/apt/sources.list.d/stretch.list
  echo "deb http://http.debian.net/debian/ stretch-updates main contrib non-free" >> /etc/apt/sources.list.d/stretch-updates.list
  echo "deb http://security.debian.org/ stretch/updates main contrib non-free" >> /etc/apt/sources.list.d/stretch-security-updates.list
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    dbus-x11
  locale-gen ru_RU.UTF-8
EOF
ENV LANG=ru_RU.UTF-8

RUN <<EOF
  set -eux
  opm install gitsync@${gitsync_ver}
EOF

ENTRYPOINT ["gitsync"]
CMD ["usage"]
