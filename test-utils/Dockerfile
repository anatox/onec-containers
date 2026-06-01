ARG BASE_IMAGE
ARG BASE_TAG

FROM ${BASE_IMAGE}:${BASE_TAG}

ARG TEST_UTILS_EXTRA_PACKAGES=""

# Installing additional dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<EOF
  set -eux
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    cifs-utils \
    inetutils-ping \
    net-tools \
    pandoc \
    scrot ${TEST_UTILS_EXTRA_PACKAGES}
EOF

RUN <<EOF
  set -eux
  printf '#!/bin/bash\n\nscrot "${@:2}"' | tee /usr/local/bin/nircmd
  chmod +x /usr/local/bin/nircmd
  rm -rf /etc/services.d/onec 2> /dev/null
EOF
