ARG BASE_IMAGE=localhost/onec-client:local

FROM ${BASE_IMAGE} AS base

ARG BASE_IMAGE=localhost/oscript:local
FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.authors="Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

ARG GITSYNC_VERSION

COPY --from=base /opt /opt

ENV LANG=ru_RU.UTF-8

RUN <<'EOF'
  set -eux
  opm install gitsync@${GITSYNC_VERSION}
EOF

ENTRYPOINT ["gitsync"]
CMD ["usage"]
