#!/usr/bin/env bash
set -eo pipefail


last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

docker build \
    --pull \
    --build-arg "ONEC_USERNAME=$ONEC_USERNAME" \
    --build-arg "ONEC_PASSWORD=$ONEC_PASSWORD" \
    --build-arg "ONEC_VERSION=$ONEC_VERSION" \
    -t localhost/crs:"$ONEC_VERSION" \
    -f crs/Containerfile \
    "${last_args[@]}"

docker build \
    --build-arg "ONEC_VERSION=$ONEC_VERSION" \
    -t localhost/crs-apache:"$ONEC_VERSION" \
    -f crs-apache/Containerfile \
    "${last_args[@]}"

if [[ "$PUSH" = "true" && -n "$DOCKER_REGISTRY_URL" ]]; then
    docker tag localhost/crs:"$ONEC_VERSION" "$DOCKER_REGISTRY_URL/crs:$ONEC_VERSION"
    docker push "$DOCKER_REGISTRY_URL/crs:$ONEC_VERSION"
    docker tag localhost/crs-apache:"$ONEC_VERSION" "$DOCKER_REGISTRY_URL/crs-apache:$ONEC_VERSION"
    docker push "$DOCKER_REGISTRY_URL/crs-apache:$ONEC_VERSION"
else
    echo "PUSH not enabled or DOCKER_REGISTRY_URL not set, skipping push."
fi
