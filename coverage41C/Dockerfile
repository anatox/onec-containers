ARG BASE_IMAGE=localhost/onec-jenkins-agent:local
ARG COVERAGE41C_VERSION
ARG EDT_IMAGE=localhost/edt:local

FROM ${EDT_IMAGE} AS base

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN ln -s "$(find /opt/1C -name "com._1c.g5.v8.dt.debug.*.jar" -printf '%h\n'| sort -u)" /opt/1C/edt_plugins

FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Dima Ovcharenko <d.ovcharenko90@gmail.com>, Korus Consulting LLC, \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG DEBUG_TRACE

ARG COVERAGE41C_VERSION

COPY --from=base /opt/1C/edt_plugins/com._1c.g5.v8.dt.debug.core_*.jar /opt/1C/edt_plugins/com._1c.g5.v8.dt.debug.model_*.jar /opt/1C/1CE/

ADD https://github.com/1c-syntax/Coverage41C/releases/download/v${COVERAGE41C_VERSION}/Coverage41C-${COVERAGE41C_VERSION}.tar \
    /tmp/coverage4onec/

RUN <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  tar xf /tmp/coverage4onec/Coverage41C-${COVERAGE41C_VERSION}.tar -C /opt/
  [ "${DEBUG_TRACE:-0}" -ne 0 ] && DEBUG_ARGS=(-print) || DEBUG_ARGS=()
  find /tmp -mindepth 1 "${DEBUG_ARGS[@]}" -delete || true
EOF

ENV EDT_LOCATION="/opt/1C/1CE/"
ENV PATH="/opt/Coverage41C-${COVERAGE41C_VERSION}/bin:$PATH"
