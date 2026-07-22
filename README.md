# onec-containers

[![forthebadge](http://forthebadge.com/images/badges/built-with-love.svg)](http://forthebadge.com)

В данном репозитории находятся файлы для сборки образов [Docker](https://www.docker.com) с платформой [1С:Предприятие](http://v8.1c.ru) 8. Также есть отдельные образы для запуска на [Distrobox] (https://distrobox.it).

## Оглавление

<!-- TOC -->

- [Использование](#использование)
- [Локальная сборка](#локальная-сборка)
  - [Devcontainer](#devcontainer)
- [Как использовать готовые дистрибутивы](#как-использовать-готовые-дистрибутивы)
- [Как использовать образы в Jenkins в режиме Docker Swarm](#как-использовать-образы-в-jenkins-в-режиме-docker-swarm)
  - [Настройка nethasp.ini](#настройка-nethaspini)
- [Сервер](#сервер)
- [Клиент](#клиент)
- [Клиент с поддержкой VNC](#клиент-с-поддержкой-vnc)
- [Тонкий клиент](#тонкий-клиент)
- [Хранилище конфигурации](#хранилище-конфигурации)
- [gitsync](#gitsync)
- [oscript](#oscript)
- [vanessa-runner](#vanessa-runner)
- [EDT](#edt)
- [Элемент.Скрипт (Исполнитель)](#элементскрипт-исполнитель)
- [Toolbox-образы для distrobox](#toolbox-образы-для-distrobox)

<!-- /TOC -->

## Использование

В терминале введите:

```bash
$ cp .envrc.example .envrc
```

Скорректируйте файл `.envrc` в соответствии со своим окружением:

- ONEC_USERNAME - учётная запись на [releases.1c.ru](https://releases.1c.ru)
- ONEC_PASSWORD - пароль для учётной записи на [releases.1c.ru](https://releases.1c.ru)
- ONEC_VERSION - версия платформы 1С:Предприятия для сборки образов платформы
- ONESCRIPT_VERSION - версия OneScript для сборки `oscript`/`onec-installer`
- EDT_VERSION - версия EDT для сборки образов EDT или при использовании замеров покрытия (см. `COVERAGE41C_VERSION`)
- CONTAINER_REGISTRY_URL - адрес container-registry для публикации образов
- COVERAGE41C_VERSION - версия Coverage41C
- ELEMENTSCRIPT_DOWNLOAD_TOKEN - токен для api скачивания 1С:Предприятие Элемент.Скрипт с сайта developer.1c.ru
- ELEMENTSCRIPT_VERSION - версия 1С:Предприятие Элемент.Скрипт для сборки
- TEST_UTILS_EXTRA_PACKAGES - дополнительные пакеты для `test-utils`
- NO_CACHE - установить в `true` для сборки без кеша
- PUSH - установить в `true` для публикации образов в registry

Затем экспортируйте все необходимые переменные:

```bash
source .envrc
```

Либо активировать автозагрузку с помощью [direnv](https://direnv.net/):

```bash
direnv allow
```

# Локальная сборка

```bash
source .envrc
scripts/bake.py server          # один образ
scripts/bake.py default         # все образы
REGISTRY_PREFIX=ghcr.io/user scripts/bake.py --push server  # публикация
```

# Devcontainer

Проект включает конфигурацию [devcontainer](https://containers.dev) (`.devcontainer/`) для локальной разработки:

При открытии проекта, VS Code предложит переоткрыть в контейнере → "Reopen in Container". Также можно набрать в палитре команд:

```
> Dev Containers: Reopen in Container
```

Devcontainer предоставляет:
- Docker-in-Docker для сборки образов через `docker buildx bake`
- Python 3 для `scripts/bake.py` и `scripts/bake-select.py`
- Установку direnv и автозагрузку `.envrc`
- Необходимые системные пакеты (bash, git, jq)

Файл `.devcontainer/devcontainer.json` описывает образ, фичи и postCreate-скрипт.

## Как использовать готовые дистрибутивы

Вы можете использовать готовые дистрибутивы платформы, для этого достаточно разместить их в папке `distr`. Скрипты будут автоматически использовать их для сборки образа.

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
scripts/bake.py server
```

## Клиент

[(Наверх)](#оглавление)

```bash
scripts/bake.py client
```

## Клиент с поддержкой VNC

[(Наверх)](#оглавление)

```bash
scripts/bake.py client-vnc
```

## Тонкий клиент

[(Наверх)](#оглавление)

```bash
scripts/bake.py thin-client
```

## Хранилище конфигурации

[(Наверх)](#оглавление)

```bash
scripts/bake.py crs
```

## gitsync

[(Наверх)](#оглавление)

```bash
scripts/bake.py gitsync
```

## oscript

[(Наверх)](#оглавление)

```bash
scripts/bake.py oscript
```

## vanessa-runner

[(Наверх)](#оглавление)

```bash
scripts/bake.py vanessa-runner
```

## EDT

[(Наверх)](#оглавление)

```bash
scripts/bake.py edt
```

## Элемент.Скрипт (Исполнитель)

[(Наверх)](#оглавление)

```bash
scripts/bake.py elementscript
```

## Toolbox-образы для distrobox

[(Наверх)](#оглавление)

Образы `edt-toolbox` и `client-toolbox` предназначены для использования с [distrobox](https://distrobox.it/) или [toolbx](https://containertoolbx.org/).

```bash
scripts/bake.py client-toolbox      # 1С клиент + toolbox
scripts/bake.py edt-toolbox         # EDT + toolbox
scripts/bake.py edt-toolbox-client  # EDT + 1С клиент + toolbox
```

Для использования с distrobox после сборки:

```bash
distrobox create --image localhost/edt-toolbox:local --name edt-toolbox
distrobox enter edt-toolbox
```
