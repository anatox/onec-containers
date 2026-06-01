#!/usr/bin/env bash
set -eo pipefail


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
    --build-arg "ONEC_VERSION=$ONEC_VERSION" \
    -t localhost/onec-server:"$ONEC_VERSION" \
    -f server/Containerfile \
    "${last_args[@]}"

if [[ "$PUSH" = "true" && -n "$DOCKER_REGISTRY_URL" ]]; then
    docker tag localhost/onec-server:"$ONEC_VERSION" "$DOCKER_REGISTRY_URL/onec-server:$ONEC_VERSION"
    docker push "$DOCKER_REGISTRY_URL/onec-server:$ONEC_VERSION"
else
    echo "PUSH not enabled or DOCKER_REGISTRY_URL not set, skipping push."
fi
