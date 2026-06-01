#!/usr/bin/env bash
set -eo pipefail


last_args=(.)
if [ "${NO_CACHE}" = 'true' ] ; then
    last_args=(--no-cache .)
fi

./build-edt.sh

export PUSH_AGENT='false'
./build-base-swarm-jenkins-agent.sh

docker build \
   --build-arg BASE_IMAGE=localhost/base-jenkins-agent \
   --build-arg "BASE_TAG=$ONEC_VERSION" \
   --build-arg "EDT_VERSION=$EDT_VERSION" \
   --build-arg "COVERAGE41C_VERSION=$COVERAGE41C_VERSION" \
   -t localhost/base-jenkins-coverage-agent:"$ONEC_VERSION" \
   -f coverage41C/Containerfile \
   "${last_args[@]}"

if [[ "$PUSH" = "true" && -n "$DOCKER_REGISTRY_URL" ]]; then
    docker tag localhost/base-jenkins-coverage-agent:"$ONEC_VERSION" "$DOCKER_REGISTRY_URL/base-jenkins-coverage-agent:$ONEC_VERSION"
    docker push "$DOCKER_REGISTRY_URL/base-jenkins-coverage-agent:$ONEC_VERSION"
else
    echo "PUSH not enabled or DOCKER_REGISTRY_URL not set, skipping push."
fi
