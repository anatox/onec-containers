ARG BASE_IMAGE=ubuntu:26.04
ARG INSTALLER_IMAGE=localhost/onec-installer:local

FROM ${INSTALLER_IMAGE} AS installer

ARG ONEC_VERSION
ARG NLS_ENABLED=false

COPY ./distr /distr

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  set -euxo pipefail
  chmod 777 -R /tmp
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    libwebkit2gtk-4.1-0
  if [ -d /usr/share/applications ]; then find /usr/share/applications -maxdepth 1 -name '*.desktop' -delete; fi
EOF

RUN --mount=type=cache,id=distr-cache,target=/var/cache/yard,sharing=locked \
    --mount=type=secret,id=onec_username \
    --mount=type=secret,id=onec_password <<'EOF'
  set -euxo pipefail
  export ONEC_USERNAME="$(cat /run/secrets/onec_username)"
  export ONEC_PASSWORD="$(cat /run/secrets/onec_password)"
  onec-install --nls="$NLS_ENABLED" thin-client "$ONEC_VERSION"
EOF

FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.authors="Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

ARG onec_uid="999"
ARG onec_gid="999"

COPY --from=installer /opt /opt

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  set -euxo pipefail
  apt-get update -qq
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
  DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    locales \
    ca-certificates \
    libwebkit2gtk-4.1-0 \
    ttf-mscorefonts-installer \
    libfontconfig1 \
    libgsf-1-114 \
    libglib2.0-0 \
    libodbc2 \
    libmagickwand-7.q16-10 \
    dbus-x11
  locale-gen ru_RU.UTF-8
  if [ -d /usr/share/applications ]; then find /usr/share/applications -maxdepth 1 -name '*.desktop' -delete; fi
EOF
# Установка переменных окружения для корректной работы локали
ENV LANG=ru_RU.UTF-8

COPY --from=installer /usr/share/applications /usr/share/applications

RUN <<'EOF'
  set -euxo pipefail
  groupadd -r grp1cv8 --gid=$onec_gid
  useradd -r -g grp1cv8 --uid=$onec_uid --home-dir=/home/usr1cv8 --shell=/bin/bash usr1cv8
  mkdir -p /home/usr1cv8/.1cv8
  chown -R usr1cv8:grp1cv8 /home/usr1cv8
EOF

VOLUME /home/usr1cv8/.1cv8

USER usr1cv8

CMD ["/opt/1C/v8.3/x86_64/1cv8c"]
