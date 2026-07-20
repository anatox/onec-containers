ARG BASE_IMAGE

# BASE_IMAGE must contain s6-overlay
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Dima Ovcharenko <d.ovcharenko90@gmail.com>, Korus Consulting LLC, \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
# hadolint ignore=DL3002
USER root

# FIX: remove old libstdc++ and libgcc_s shipped with 1C (causes GLIBCXX/GCC version errors)
RUN find /opt/1cv8 \( -name "libgcc_s.so*" -o -name "libstdc++.so*" \) -delete

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  apt-mark hold iptables
  env DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
    dbus-x11 \
    x11-xserver-utils \
    x11-utils \
    xvfb \
    x11vnc \
    xfce4 \
    xfce4-goodies \
    libsm6 \
    libxcb-icccm4 \
    libx11-xcb1 \
    psmisc \
    xdg-utils \
    iproute2
  # Fix xfce theme
  sed -i 's%<property name="ThemeName" type="string" value="Xfce"/>%<property name="ThemeName" type="string" value="Raleigh"/>%' \
    /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
EOF

# Disable accessibility
ENV NO_AT_BRIDGE=1

# Fix WebKit / GTK issues in containers
ENV QT_X11_NO_MITSHM=1

# Disable session manager
ENV XDG_SESSION_TYPE=x11

# Skip window manager registration check
RUN echo "xfce4-panel --disable-wm-check" >> ~/.xsession

# add services to s6-overlay
COPY ./client-vnc/configs/rootfs-v3/ /

ENV S6_KEEP_ENV=1

ENV DISPLAY=:0
ENV DISPLAY_WIDTH=1440
ENV DISPLAY_HEIGHT=900

EXPOSE 5900

ENTRYPOINT ["/init"]
