ARG DOCKER_REGISTRY_URL
ARG BASE_IMAGE
ARG BASE_TAG

# BASE_IMAGE must contain s6-overlay
FROM ${DOCKER_REGISTRY_URL}${DOCKER_REGISTRY_URL:+/}${BASE_IMAGE}:${BASE_TAG}

LABEL maintainer="Dima Ovcharenko <d.ovcharenko90@gmail.com>, Korus Consulting LLC"

USER root

# FIX: remove old libstdc++ shipped with 1C (causes GLIBCXX errors)
RUN find /opt/1cv8 -name "libstdc++.so*" -delete

RUN apt-get update \
  && apt-mark hold iptables \
  && env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    # X11 и VNC
    dbus-x11 \
    x11-xserver-utils \
    x11-utils \
    xvfb \
    x11vnc \
    # Desktop environment
    xfce4 \
    xfce4-goodies \
    libsm6 \
    libxcb-icccm4 \
    libx11-xcb1 \
    # Utilities
    psmisc \
    xdg-utils \
    iproute2 \
  # Fix xfce theme
  && sed -i 's%<property name="ThemeName" type="string" value="Xfce"/>%<property name="ThemeName" type="string" value="Raleigh"/>%' \
    /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml \
  && rm -rf \
    /var/lib/apt/lists/* \
    /var/cache/debconf \
    /tmp/* \
    /var/tmp/*

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
