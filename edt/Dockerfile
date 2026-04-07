# Используем базовый образ для скачивания
ARG DOWNLOADER_REGISTRY_URL
ARG DOWNLOADER_IMAGE
ARG DOWNLOADER_TAG

# Для EDT 2025.x ОБЯЗАТЕЛЬНО используем Java 17
ARG BASE_IMAGE=eclipse-temurin
ARG BASE_TAG=17-jdk-jammy
ARG DOCKER_REGISTRY_URL

FROM ${DOWNLOADER_REGISTRY_URL:+"$DOWNLOADER_REGISTRY_URL/"}${DOWNLOADER_IMAGE}:${DOWNLOADER_TAG} AS downloader

# Копирование скрипта скачивания и локальных дистрибутивов
COPY --chmod=755 ./scripts/download_yard.sh /download.sh
COPY ./distr /distr

# Скачивание дистрибутива 1С с использованием вынесенного скрипта
ARG ONEC_USERNAME
ARG ONEC_PASSWORD
ARG EDT_VERSION=2021.3

WORKDIR /tmp

# Установка необходимых пакетов и генерация локали
RUN apt-get update \
  && apt-get install -y \
          locales \
          p7zip-rar \
          p7zip-full \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen ru_RU.UTF-8 \
  && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8

# Установка переменных окружения для корректной работы локали
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

RUN /download.sh "$ONEC_USERNAME" "$ONEC_PASSWORD" "$EDT_VERSION" "edt"

FROM ${BASE_IMAGE}:${BASE_TAG} AS installer

LABEL maintainer="Nikita Gryzlov <NikGryzlov@1bit.com>, FirstBit"

ARG EDT_VERSION=2021.3
ARG downloads=downloads/DevelopmentTools10/${EDT_VERSION}

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    # downloader dependencies
    curl \
    # edt dependencies
    libgtk-3-0 \
    locales \
    libc-bin \
    coreutils \
  && rm -rf  \
    /var/lib/apt/lists/* \
    /var/cache/debconf \
    /tmp/* \
  && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \
  && echo '#!/bin/sh\nif [ "$1" = "LONG_BIT" ]; then echo "64"; else echo "unknown"; fi' > /usr/local/bin/getconf \
  && chmod +x /usr/local/bin/getconf

# Install EDT
COPY --from=downloader /tmp/${downloads} /tmp/${downloads}

WORKDIR /tmp/${downloads}

RUN chmod -R +x . \
  && ./1ce-installer-cli install all --ignore-hardware-checks --ignore-signature-warnings \
  && ln -s $(dirname $(find /opt/1C/1CE -name ring)) /opt/1C/1CE/components/1c-enterprise-ring \
  #1cedtcli отсутствует в EDT версии <2023.1.0
  && if [ -n "$(find /opt/1C/1CE -name 1cedtcli)" ]; then ln -s $(dirname $(find /opt/1C/1CE -name 1cedtcli)) /opt/1C/1CE/components/1cedtcli; fi \
  && rm -rf \
    /tmp/* \
  # создадим пустой файл, чтобы не было ошибок на следуюших этапах в случае его отсутствия
  && if [ ! -f /etc/1C/1CE/ring-commands.cfg ]; then touch /etc/1C/1CE/ring-commands.cfg; fi \
  && rm /usr/local/bin/getconf

FROM ${BASE_IMAGE}:${BASE_TAG}

LABEL maintainer="Nikita Gryzlov <NikGryzlov@1bit.com>, FirstBit"

WORKDIR /tmp

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    # downloader dependencies
    curl \
    # edt dependencies
    libgtk-3-0 \
    locales \
  && rm -rf  \
    /var/lib/apt/lists/* \
    /var/cache/debconf \
    /tmp/* \
  && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8

# Установка переменных окружения для корректной работы локали
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

# Copy EDT
COPY --from=installer /opt/1C/1CE /opt/1C/1CE

# Copy ring conf
COPY --from=installer /etc/1C/1CE/ring-commands.cfg /etc/1C/1CE/ring-commands.cfg

ENV PATH="/opt/1C/1CE/components/1c-enterprise-ring:/opt/1C/1CE/components/1cedtcli:$PATH"
