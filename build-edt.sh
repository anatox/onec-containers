#!/usr/bin/env bash
set -eo pipefail


#Если версия EDT >= 2024.1.0, использовать JDK 17
if [[ "$EDT_VERSION" == 2024* ]] || [[ "$EDT_VERSION" == 2025* ]]; then
  # Для новых версий используем Ubuntu + Java 17
  # (Это надежнее, чем просто голая Java-платформа)
  BASE_IMAGE="eclipse-temurin"
  BASE_TAG="${OPENJDK_VERSION}-jdk-noble"
else
  BASE_IMAGE="eclipse-temurin"
  BASE_TAG="11-jdk-focal"
fi

last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

docker build \
    --pull \
    --build-arg BASE_IMAGE=ubuntu \
    --build-arg BASE_TAG=24.04 \
    --build-arg "ONESCRIPT_VERSION=$ONESCRIPT_VERSION" \
    --build-arg ONESCRIPT_PACKAGES="yard" \
    -t localhost/oscript-downloader:latest \
    -f oscript/Containerfile \
    "${last_args[@]}"

docker build \
    --build-arg "ONEC_USERNAME=$ONEC_USERNAME" \
    --build-arg "ONEC_PASSWORD=$ONEC_PASSWORD" \
    --build-arg "EDT_VERSION=$EDT_VERSION" \
    --build-arg "OPENJDK_VERSION=$OPENJDK_VERSION" \
    --build-arg "BASE_IMAGE=$BASE_IMAGE" \
    --build-arg "BASE_TAG=$BASE_TAG" \
    -t localhost/edt:"$EDT_VERSION" \
    -f edt/Containerfile \
    "${last_args[@]}"
