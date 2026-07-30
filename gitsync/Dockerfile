ARG BASE_IMAGE=localhost/onec-client:local

FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Anton Kvashenkin <anton.jugatsu@gmail.com> (@jugatsu), \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG DEBUG_TRACE

ARG GITSYNC_VERSION

RUN <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  opm install gitsync@${GITSYNC_VERSION}
EOF

ENTRYPOINT ["gitsync"]
CMD ["usage"]
