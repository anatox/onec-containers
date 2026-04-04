ARG DOCKER_REGISTRY_URL
ARG BASE_IMAGE=debian
ARG BASE_TAG=bookworm-slim

FROM ${DOCKER_REGISTRY_URL:+"$DOCKER_REGISTRY_URL/"}${BASE_IMAGE}:${BASE_TAG}

LABEL maintainer="Dima Ovcharenko <d.ovcharenko90@gmail.com>, Korus Consulting LLC"

USER root

RUN apt-get update \
  && apt-mark hold iptables \
  && env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    xz-utils

# Install s6-overlay v3
ARG S6_OVERLAY_VERSION=3.2.2.0
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz \
  && rm -f /tmp/s6-overlay-*.tar.xz

ENTRYPOINT ["/init"]
