# Примеры сборки и наслаивания

Ниже список последовательно собираемых образов для различных целей. Каждый следующий слой собирается поверх предыдущего. В Containerfile базовый образ указывается через `ARG BASE_IMAGE=<имя>:<тег>`.

## Запуск 1С

* client
* s6-overlay
* client-vnc

## 1С и OneScript

* client
* s6-overlay
* client-vnc
* oscript

## 1С + OneScript для запуска VA

* client
* s6-overlay
* client-vnc
* oscript
* test-utils

## 1C как Jenkins агент

* client
* s6-overlay
* client-vnc
* jdk
* swarm-jenkins-agent или k8s-jenkins-agent

## 1С + OneScript как Jenkins агент

* client
* s6-overlay
* client-vnc
* oscript
* jdk
* swarm-jenkins-agent или k8s-jenkins-agent

## 1С + OneScript как Jenkins агент для запуска тестов

* client
* s6-overlay
* client-vnc
* oscript
* jdk
* test-utils
* swarm-jenkins-agent или k8s-jenkins-agent

Реализовано в скриптах:

* [build-base-swarm-jenkins-agent.sh](build-base-swarm-jenkins-agent.sh)
* [build-base-k8s-jenkins-agent.sh](build-base-k8s-jenkins-agent.sh)

## 1С + OneScript как Jenkins агент с покрытием (coverage41C)

* client
* s6-overlay
* client-vnc
* oscript
* jdk
* test-utils
* swarm-jenkins-agent или k8s-jenkins-agent
* coverage41C

Реализовано в скриптах:

* [build-base-swarm-jenkins-coverage-agent.sh](build-base-swarm-jenkins-coverage-agent.sh)
* [build-base-k8s-jenkins-coverage-agent.sh](build-base-k8s-jenkins-coverage-agent.sh)

## EDT

* edt

Собирается через Pants (`pants package edt:edt-2026.1.2`). Для phase-4 локальной сборки агентов: `buildah build --secret=id=secrets_env,src=secrets.env --build-arg INSTALLER_IMAGE=localhost/onec-installer:local --build-arg EDT_VERSION=2026.1.2 -f edt/Containerfile .`

## EDT как Jenkins агент

* edt
* s6-overlay
* swarm-jenkins-agent или k8s-jenkins-agent

Реализовано в скриптах:

* [build-edt-swarm-agent.sh](build-edt-swarm-agent.sh)
* [build-edt-k8s-agent.sh](build-edt-k8s-agent.sh)

## OneScript как Jenkins агент

* oscript поверх eclipse-temurin:17
* s6-overlay
* swarm-jenkins-agent или k8s-jenkins-agent

Реализовано в скриптах:

* [build-oscript-swarm-agent.sh](build-oscript-swarm-agent.sh)
* [build-oscript-k8s-agent.sh](build-oscript-k8s-agent.sh)

## Сервер хранилища + Apache

* crs
* crs-apache

Собирается через Pants.

## Toolbox-образы (distrobox)

* edt-toolbox = EDT поверх ubuntu-toolbox
* edt-toolbox-client = edt-toolbox + client файлы (COPY --from onec-client)

Собираются через Pants (`pants package client:client-toolbox-8.5.1.1343`, `pants package edt:edt-toolbox-2026.1.2-client-8.5.1.1343`). Клиентские файлы попадают из собранного `onec-client` образа через `COPY --from=client-src`, а не через повторный `onec-install client`.

## Примечание

oscript, installer, client, client-toolbox, edt, edt-toolbox, server, crs, thin-client, vanessa-runner, gitsync, executor собираются через Pants (нет отдельных build-скриптов). EDT toolbox-образы требуют предварительной сборки `oscript → installer`. Исключение: oscript-агент использует `eclipse-temurin:17` напрямую.
