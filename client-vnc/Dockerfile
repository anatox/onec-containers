ARG DOCKER_REGISTRY_URL
ARG ONEC_VERSION
FROM ${DOCKER_REGISTRY_URL}${DOCKER_REGISTRY_URL:+/}onec-client:${ONEC_VERSION}

LABEL maintainer="Dima Ovcharenko <d.ovcharenko90@gmail.com>, Korus Consulting LLC"

USER root

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
    # Utilities
    psmisc \
    xdg-utils \
  # Fix xfce theme
  && sed -i 's%<property name="ThemeName" type="string" value="Xfce"/>%<property name="ThemeName" type="string" value="Raleigh"/>%' \
    /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml \
  && rm -rf \
    /var/lib/apt/lists/* \
    /var/cache/debconf \
    /tmp/* \
    /var/tmp/*

# must be built on top of s6-overlay layer

# add services to s6-overlay
COPY ./client-vnc/configs/rootfs-v3/ /

ENV S6_KEEP_ENV=1

ENV DISPLAY=:0
ENV DISPLAY_WIDTH=1440
ENV DISPLAY_HEIGHT=900

EXPOSE 5900

ENTRYPOINT ["/init"]
