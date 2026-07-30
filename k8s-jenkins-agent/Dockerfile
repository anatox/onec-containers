# Для сборки использован стандартный шаблон jenkins-inbound-agent https://github.com/jenkinsci/docker-agent/blob/master/debian/Dockerfile
# Стадию с as jre-build убрал, т.к. у нас на этот момент уже всегда есть джава в контейнере.
ARG BASE_IMAGE=ubuntu:26.04

FROM ${BASE_IMAGE} AS agent

LABEL org.opencontainers.image.authors="Nikita Gryzlov <NikGryzlov@1bit.com>, FirstBit, \
    Anatolii Sereda <3011745+anatox@users.noreply.github.com>"

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG DEBUG_TRACE

RUN <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  groupadd -g "${gid}" "${group}" || getent group "${gid}" | cut -d: -f1 | xargs -I{} groupmod -n "${group}" {}
  useradd -l -c "Jenkins user" -d /home/"${user}" -u "${uid}" -g "${gid}" -m "${user}" || echo "user ${user} already exists."
EOF

ARG AGENT_WORKDIR=/home/"${user}"/agent

## Always use the latest Debian packages: no need for versions
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked <<'EOF'
  [ "${DEBUG_TRACE:-0}" = "1" ] && set -x
  find /var/lib/apt/lists -name lock -delete 2>/dev/null || true
  apt-get update -qq
  apt-get --yes --no-install-recommends install \
    ca-certificates \
    curl \
    fontconfig \
    git \
    git-lfs \
    less \
    netbase \
    openssh-client \
    patch \
    tzdata
EOF

ARG VERSION
ADD --chown="${user}":"${group}" "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar" /usr/share/jenkins/agent.jar
RUN chmod 0644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir -p /home/"${user}"/.jenkins && mkdir -p "${AGENT_WORKDIR}"

VOLUME /home/"${user}"/.jenkins
VOLUME "${AGENT_WORKDIR}"
WORKDIR /home/"${user}"
ENV USER=${user}
LABEL \
  org.opencontainers.image.vendor="Jenkins project" \
  org.opencontainers.image.title="Official Jenkins Agent Base Docker image" \
  org.opencontainers.image.description="This is a base image, which provides the Jenkins agent executable (agent.jar)" \
  org.opencontainers.image.version="${VERSION}" \
  org.opencontainers.image.url="https://www.jenkins.io/" \
  org.opencontainers.image.source="https://github.com/jenkinsci/docker-agents" \
  org.opencontainers.image.licenses="MIT"

## Inbound Agent image target
FROM agent AS inbound-agent

ARG user=jenkins

# hadolint ignore=DL3002
USER root
COPY --chmod=755 ./k8s-jenkins-agent/jenkins-agent /usr/local/bin/jenkins-agent
COPY --chmod=755 ./k8s-jenkins-agent/docker-entrypoint.sh /docker-entrypoint.sh

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
ARG DEBUG_TRACE
RUN ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave

# USER ${user}

LABEL \
  org.opencontainers.image.vendor="Jenkins project" \
  org.opencontainers.image.title="Official Jenkins Inbound Agent Base Docker image" \
  org.opencontainers.image.description="This is an image for Jenkins agents using TCP or WebSockets to establish inbound connection to the Jenkins controller" \
  org.opencontainers.image.version="${VERSION}" \
  org.opencontainers.image.url="https://www.jenkins.io/" \
  org.opencontainers.image.source="https://github.com/jenkinsci/docker-agents" \
  org.opencontainers.image.licenses="MIT"

ENTRYPOINT ["/docker-entrypoint.sh"]
