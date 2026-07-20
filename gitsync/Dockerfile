ARG BASE_IMAGE=localhost/onec-client:local

FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.authors="Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

ARG GITSYNC_VERSION

RUN <<'EOF'
  set -eux
  opm install gitsync@${GITSYNC_VERSION}
EOF

ENTRYPOINT ["gitsync"]
CMD ["usage"]
