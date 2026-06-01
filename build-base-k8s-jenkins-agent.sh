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
    -t localhost/onec-client:"$ONEC_VERSION" \
    -f client/Containerfile \
    "${last_args[@]}"

docker build \
    --build-arg BASE_IMAGE=localhost/onec-client \
    --build-arg "BASE_TAG=$ONEC_VERSION" \
    -t localhost/onec-client-s6:"$ONEC_VERSION" \
    -f s6-overlay/Containerfile \
    "${last_args[@]}"

docker build \
    --pull \
    --build-arg BASE_IMAGE=localhost/onec-client-s6 \
    --build-arg "BASE_TAG=$ONEC_VERSION" \
    -t localhost/onec-client-vnc:"$ONEC_VERSION" \
    -f client-vnc/Containerfile \
    "${last_args[@]}"

docker build \
    --build-arg BASE_IMAGE=localhost/onec-client-vnc \
    --build-arg "BASE_TAG=$ONEC_VERSION" \
    -t localhost/onec-client-vnc-oscript:"$ONEC_VERSION" \
    -f oscript/Containerfile \
    "${last_args[@]}"

docker build \
    --build-arg BASE_IMAGE=localhost/onec-client-vnc-oscript \
    --build-arg "BASE_TAG=$ONEC_VERSION" \
    -t localhost/onec-client-vnc-oscript-jdk:"$ONEC_VERSION" \
    -f jdk/Containerfile \
    "${last_args[@]}"

docker build \
    --build-arg BASE_IMAGE=localhost/onec-client-vnc-oscript-jdk \
    --build-arg "BASE_TAG=$ONEC_VERSION" \
    --build-arg "TEST_UTILS_EXTRA_PACKAGES=$TEST_UTILS_EXTRA_PACKAGES" \
    -t localhost/onec-client-vnc-oscript-jdk-testutils:"$ONEC_VERSION" \
    -f test-utils/Containerfile \
    "${last_args[@]}"

docker build \
    --build-arg BASE_IMAGE=localhost/onec-client-vnc-oscript-jdk-testutils \
    --build-arg "BASE_TAG=$ONEC_VERSION" \
    -t localhost/base-jenkins-agent:"$ONEC_VERSION" \
    -f k8s-jenkins-agent/Containerfile \
    "${last_args[@]}"

if [[ "$PUSH" = "true" && -n "$DOCKER_REGISTRY_URL" ]]; then
    docker tag localhost/onec-client:"$ONEC_VERSION" "$DOCKER_REGISTRY_URL/onec-client:$ONEC_VERSION"
    docker push "$DOCKER_REGISTRY_URL/onec-client:$ONEC_VERSION"
    docker tag localhost/onec-client-s6:"$ONEC_VERSION" "$DOCKER_REGISTRY_URL/onec-client-s6:$ONEC_VERSION"
    docker push "$DOCKER_REGISTRY_URL/onec-client-s6:$ONEC_VERSION"
    docker tag localhost/onec-client-vnc:"$ONEC_VERSION" "$DOCKER_REGISTRY_URL/onec-client-vnc:$ONEC_VERSION"
    docker push "$DOCKER_REGISTRY_URL/onec-client-vnc:$ONEC_VERSION"
    if [[ "$PUSH_AGENT" != "false" ]]; then
        docker tag localhost/base-jenkins-agent:"$ONEC_VERSION" "$DOCKER_REGISTRY_URL/base-jenkins-agent:$ONEC_VERSION"
        docker push "$DOCKER_REGISTRY_URL/base-jenkins-agent:$ONEC_VERSION"
    fi
else
    echo "PUSH not enabled or DOCKER_REGISTRY_URL not set, skipping push."
fi
