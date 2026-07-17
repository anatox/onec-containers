# onec-containers

[![forthebadge](http://forthebadge.com/images/badges/built-with-love.svg)](http://forthebadge.com)

В данном репозитории находятся файлы для сборки образов OCI-контейнеров с платформой [1С:Предприятие](http://v8.1c.ru) 8.3.

## Оглавление

<!-- TOC -->

- [Описание](#описание)
  - [Оглавление](#оглавление)
  - [Использование](#использование)
  - [Сборка через CI (Pants)](#сборка-через-ci-pants)
    - [Модель версий](#модель-версий)
    - [Теги образов](#теги-образов)
    - [Матрица сборок](#матрица-сборок)
  - [Локальная сборка](#локальная-сборка)
    - [Через Devcontainer (рекомендуется)](#через-devcontainer-рекомендуется)
    - [Без devcontainer](#без-devcontainer)
    - [Изменение версий](#изменение-версий)
  - [Как использовать образы в Jenkins в режиме Docker Swarm](#как-использовать-образы-в-jenkins-в-режиме-docker-swarm)
    - [Настройка nethasp.ini](#настройка-nethaspini)
  - [Сервер](#сервер)
  - [Сервер с дополнительными языками](#сервер-с-дополнительными-языками)
  - [Клиент](#клиент)
  - [Клиент с поддержкой VNC](#клиент-с-поддержкой-vnc)
  - [Клиент с дополнительными языками](#клиент-с-дополнительными-языками)
  - [Тонкий клиент](#тонкий-клиент)
  - [Тонкий клиент с дополнительными языками](#тонкий-клиент-с-дополнительными-языками)
  - [Хранилище конфигурации](#хранилище-конфигурации)
  - [Хранилище конфигурации с Apache](#хранилище-конфигурации-с-apache)
  - [gitsync](#gitsync)
  - [oscript](#oscript)
  - [vanessa-runner](#vanessa-runner)
  - [EDT](#edt)
  - [Исполнитель](#исполнитель)
  - [Toolbox-образы для distrobox](#toolbox-образы-для-distrobox)
    - [Сборка CI (GitHub Actions)](#сборка-ci-github-actions)
    - [Локальная сборка Toolbox-образов](#локальная-сборка-toolbox-образов)
    - [Проверка подписи образа](#проверка-подписи-образа)

<!-- /TOC -->

## Использование

В терминале введите:

```bash
$ cp .envrc.example .envrc
```

Скорректируйте файл `.envrc` в соответствии со своим окружением:

- ONEC_VERSION — версия платформы 1С:Предприятия для сборки образов платформы
- ONESCRIPT_VERSION — версия OneScript для сборки `oscript`/`onec-installer`
- EDT_VERSION — версия EDT для сборки образов EDT или при использовании замеров покрытия
- CONTAINER_REGISTRY_URL — адрес container-registry для публикации образов
- EXECUTOR_VERSION — версия 1С:Исполнитель для сборки

Затем экспортируйте все необходимые переменные:

```bash
source .envrc
```

Либо активировать автозагрузку с помощью [direnv](https://direnv.net/):

```bash
direnv allow
```

## Сборка через CI (Pants)

Образы собираются через [Pants](https://www.pantsbuild.org/) с `pants.backend.docker`. При push в `main` CI автоматически выбирает изменившиеся docker-образы (`--changed-since`) и публикует их в `ghcr.io/<owner>/`. Автопубликацию можно отключить через `vars.PUBLISH=false`. Для принудительной пересборки используйте `workflow_dispatch` в `release.yml` с указанием Pants-таргета (например, `server:`).

### Модель версий

Версии компонентов хранятся в отдельных файлах в `versions/`: `platform.py`, `oscript.py`, `yard.py`, `executor.py`, `gitsync.py`, `vanessa_runner.py`. Вспомогательные функции — в `build_support/helpers.py`. Изменение любого файла в `versions/` инвалидирует все BUILD-файлы и вызывает пересборку всех образов (registry cache делает untouched-сборки почти мгновенными).

### Теги образов

- **`<version>`** — мутабельный тег (всегда указывает на последнюю сборку версии)
- **`<version>-g<shortsha>`** — иммутабельный тег (привязан к конкретному коммиту)
- **`latest`** — только на образы последней версии в каждой цепочке (основная ветка)
- **`local`** — локальные сборки (без публикации в registry)

### Матрица сборок

Каждый образ + версия получает отдельную job в матрице CI (`release / onec-server 8.5.1.1343`), обеспечивая независимую видимость и параллелизм.

## Локальная сборка

### Через Devcontainer (рекомендуется)

Откройте репозиторий в VS Code с расширением Dev Containers. Контейнер включает docker-in-docker, direnv и Pants launcher.

```bash
# Создать secrets.env из примера и заполнить учётными данными
cp secrets.env.example secrets.env

# В devcontainer достаточно запустить
pants package server:onec-server-8.5.1.1343
```

### Без devcontainer

```bash
# Скопировать пример конфигурации и заполнить учётными данными
cp secrets.env.example secrets.env

# Загрузить Pants launcher
curl -fsSL https://static.pantsbuild.org/setup/pants-2.32.sh | bash

# Сборка сервера (pants соберёт oscript → installer → server автоматически)
pants package server:onec-server-8.5.1.1343
```

### Изменение версий

Версии меняются в файлах из `versions/`. Например, чтобы добавить новую версию платформы в `versions/platform.py`:

```python
PLATFORM_VERSIONS = ["8.3.27.1936", "8.5.1.1343"]
```

После изменения `pants package server:` соберёт образы для обеих версий.

## Как использовать образы в Jenkins в режиме Docker Swarm

Поддерживаемые плагины:

- [Swarm Agents Cloud](https://plugins.jenkins.io/swarm-agents-cloud/)

> ⚠️ ВНИМАНИЕ! При настройке шаблонов агентов в плагине Swarm Agents Cloud необходимо раскрыть раздел `Advanced` и установить флажок `Disable Container Args`.

- [Docker Swarm (устарел)](https://plugins.jenkins.io/docker-swarm/)

### Настройка nethasp.ini

- взять ваш файл nethasp.ini
- создать из него docker config командой `docker config create nethasp.ini ./nethasp.ini`
- в Jenkins, в настройках Docker Agent templates у соответствующих агентов в параметре Configs указать `nethasp.ini:/opt/1cv8/current/conf/nethasp.ini`

## Сервер

[(Наверх)](#оглавление)

```bash
pants package server:onec-server-8.5.1.1343
```

## Сервер с дополнительными языками

[(Наверх)](#оглавление)

```bash
NLS_ENABLED=true pants package server:onec-server-8.5.1.1343
```

## Клиент

[(Наверх)](#оглавление)

```bash
pants package client:onec-client-8.5.1.1343
```

## Клиент с поддержкой VNC

[(Наверх)](#оглавление)

```bash
pants package client-vnc:onec-client-vnc-8.5.1.1343
```

## Клиент с дополнительными языками

[(Наверх)](#оглавление)

```bash
NLS_ENABLED=true pants package client:onec-client-8.5.1.1343
```

## Тонкий клиент

[(Наверх)](#оглавление)

```bash
pants package thin-client:onec-thin-client-8.5.1.1343
```

## Тонкий клиент с дополнительными языками

[(Наверх)](#оглавление)

```bash
NLS_ENABLED=true pants package thin-client:onec-thin-client-8.5.1.1343
```

## Хранилище конфигурации

[(Наверх)](#оглавление)

```bash
pants package crs:onec-crs-8.5.1.1343
```

## Хранилище конфигурации с Apache

[(Наверх)](#оглавление)

```bash
pants package crs-apache:onec-crs-apache-8.5.1.1343
```

## gitsync

[(Наверх)](#оглавление)

```bash
pants package gitsync:gitsync
```

## oscript

[(Наверх)](#оглавление)

```bash
pants package oscript:oscript
```

## vanessa-runner

[(Наверх)](#оглавление)

```bash
pants package vanessa-runner:runner
```

## EDT

[(Наверх)](#оглавление)

```bash
pants package edt:edt-2026.1.2
```

## Исполнитель

[(Наверх)](#оглавление)

```bash
pants package executor:executor-7.0.3.3
```

## Toolbox-образы для distrobox

[(Наверх)](#оглавление)

Образы `edt-toolbox` и `client-toolbox` предназначены для использования с [distrobox](https://distrobox.it/) или [toolbx](https://containertoolbx.org/).
Они включают те же компоненты, что и обычные образы EDT/клиент, но построены на базе `quay.io/toolbx/ubuntu-toolbox` и содержат shim-ссылки для прозрачного вызова `docker`, `podman`, `flatpak` с хоста.

### Сборка CI (GitHub Actions)

Toolbox-образы собираются в `release.yml` как часть общей Pants-матрицы. Целевые таргеты:

- `client:client-toolbox-8.5.1.1343` — сборка `client-toolbox`
- `edt:edt-toolbox-2026.1.2-client-8.5.1.1343` — сборка `edt-toolbox`

Теги: `<version>`, `<version>-g<sha>` (иммутабельный), `latest` (последняя версия, main).

### Локальная сборка Toolbox-образов

```bash
pants package client:client-toolbox-8.5.1.1343
pants package edt:edt-toolbox-2026.1.2-client-8.5.1.1343
```

Для использования с distrobox после сборки:

```bash
# Создать и войти в контейнер
distrobox create --image localhost/edt-toolbox:latest --name edt-toolbox
distrobox enter edt-toolbox
```

### Проверка подписи образа

```bash
cosign verify --key cosign.pub ghcr.io/<owner>/edt-toolbox:latest
cosign verify --key cosign.pub ghcr.io/<owner>/client-toolbox:latest
```
