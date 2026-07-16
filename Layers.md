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

Реализовано в скриптах:

* [build-edt.sh](build-edt.sh)

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

* edt-toolbox
* client-toolbox (поверх edt-toolbox)

Реализовано в скриптах:

* [build-client-toolbox.sh](build-client-toolbox.sh)
* [build-edt-toolbox.sh](build-edt-toolbox.sh)

## Примечание

oscript, installer, client, server, crs собираются через Pants (нет отдельных build-скриптов). EDT и toolbox-образы требуют предварительной сборки `oscript → installer` (в CI — composite action `build-installer`, в локальных скриптах шаги явно прописаны). Исключение: oscript-агент использует `eclipse-temurin:17` напрямую.
