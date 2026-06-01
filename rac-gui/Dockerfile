ARG DOCKER_REGISTRY_URL=localhost
ARG ONEC_VERSION
FROM ${DOCKER_REGISTRY_URL:+"$DOCKER_REGISTRY_URL"/}onec:${ONEC_VERSION}-server
LABEL maintainer="Anton Kvashenkin <anton.jugatsu@gmail.com> (@jugatsu)"

ARG gui_ver=1.0.1
ARG gui_url=https://nuk-svk.ru/uploads/rac-gui

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tk8.6 \
    tcl8.6 \
    tk \
    ca-certificates \
    wget
  wget $gui_url/rac_gui-"$gui_ver".deb
  dpkg -x rac_gui-$gui_ver.deb /tmp
  mv /tmp/usr/share/rac_gui /usr/share
  mv /tmp/usr/bin/racgui /usr/bin
  rm -f rac_gui-$gui_ver.deb
EOF

CMD ["racgui"]
