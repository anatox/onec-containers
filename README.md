# Описание

[![forthebadge](http://forthebadge.com/images/badges/built-with-love.svg)](http://forthebadge.com)

В данном репозитории находятся файлы для сборки образов [Docker](https://www.docker.com) с платформой [1С:Предприятие](http://v8.1c.ru) 8.3.

## Оглавление

- [Описание](#описание)
  - [Оглавление](#оглавление)
  - [Использование](#использование)
  - [Как сбилдить образы](#как-сбилдить-образы)
  - [Как использовать готовые дистрибутивы](#как-использовать-готовые-дистрибутивы)
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
  - [rac-gui](#rac-gui)
  - [gitsync](#gitsync)
  - [oscript](#oscript)
  - [vanessa-runner](#vanessa-runner)
  - [EDT](#edt)
  - [Исполнитель](#исполнитель)
  - [Локальное тестирование CI (act)](#локальное-тестирование-ci-act)
    - [Установка](#установка)
    - [Запуск отдельной задачи](#запуск-отдельной-задачи)
    - [Параметры](#параметры)
    - [Публикация образов](#публикация-образов)
    - [Известные особенности](#известные-особенности)
  - [Toolbox-образы для distrobox](#toolbox-образы-для-distrobox)
    - [Сборка CI (GitHub Actions)](#сборка-ci-github-actions)
    - [Локальная отладочная сборка client-toolbox](#локальная-отладочная-сборка-client-toolbox)
    - [Использование с distrobox](#использование-с-distrobox)
    - [Проверка подписи образа](#проверка-подписи-образа)

## Использование

В терминале введите:

Команда Linux:

```bash
# для Linux
$ cp .onec.env.example .onec.env
```

```batch
:: для Windows
copy .onec.env.bat.example env.bat
```
W
Скорректируйте файл `.onec.env` в соответствии со своим окружением:

- ONEC_USERNAME - учётная запись на [releases.1c.ru](https://releases.1c.ru)
- ONEC_PASSWORD - пароль для учётной записи на [releases.1c.ru](https://releases.1c.ru)
- ONEC_VERSION - версия платформы 1С:Предприятия 8.3, которая будет в образе
- ONESCRIPT_VERSION - версия образа `OneScript` для сборки `oscript-downloader`
- EDT_VERSION - версия EDT. Обязательно заполнять только при сборке образов с EDT или при использовании замеров покрытия (см. `COVERAGE41C_VERSION`)
- OPENJDK_VERSION - версия JDK (temurin)
- DOCKER_REGISTRY_URL - Адрес Docker-registry в котором будут храниться образы
- COVERAGE41C_VERSION - версия Coverage41C
Используется при сборке агента скриптами `build-base-*-jenkins-coverage-agent.*`.
- DEV1C_EXECUTOR_API_KEY - токен для api скачивания 1С:Исполнитель с сайта developer.1c.ru
- EXECUTOR_VERSION - версия 1С:Исполнитель для сборки
- TEST_UTILS_EXTRA_PACKAGES - дополнительные пакеты, которые будут установлены при сборке `test-utils` и которые будут доступны в финальном образе

Затем экспортируйте все необходимые переменные:

```bash
# для Linux
$ source .onec.env
```

```batch
:: для Windows
env.bat
```

## Как сбилдить образы

:point_up: Запустите последовательно скрипты для сборки образов. Для публикации в реестр передайте `PUSH=true DOCKER_REGISTRY_URL=<registry>`.

1. Если вам нужны образы для использования в docker-swarm:

    - build-base-swarm-jenkins-agent.sh (или build-base-swarm-jenkins-coverage-agent.sh с замерами покрытия)
    - build-edt-swarm-agent.sh
    - build-oscript-swarm-agent.sh

2. Если же вы планируете использовать k8s:

    - build-base-k8s-jenkins-agent.sh (или build-base-k8s-jenkins-coverage-agent.sh с замерами покрытия)
    - build-edt-k8s-agent.sh
    - build-oscript-k8s-agent.sh

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
docker buildx build --load \
  --build-arg ONEC_USERNAME=${ONEC_USERNAME} \
  --build-arg ONEC_PASSWORD=${ONEC_PASSWORD} \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/onec-server:${ONEC_VERSION} \
  -f server/Dockerfile .
```

## Сервер с дополнительными языками

[(Наверх)](#оглавление)

```bash
docker buildx build --load \
  --build-arg ONEC_USERNAME=${ONEC_USERNAME} \
  --build-arg ONEC_PASSWORD=${ONEC_PASSWORD} \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  --build-arg nls_enabled=true \
  -t localhost/onec-server-nls:${ONEC_VERSION} \
  -f server/Dockerfile .
```

## Клиент

[(Наверх)](#оглавление)

```bash
docker buildx build --load \
  --build-arg ONEC_USERNAME=${ONEC_USERNAME} \
  --build-arg ONEC_PASSWORD=${ONEC_PASSWORD} \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/onec-client:${ONEC_VERSION} \
  -f client/Dockerfile .
```

## Клиент с поддержкой VNC

[(Наверх)](#оглавление)

```bash
# Предварительно соберите onec-client и onec-client-s6 (см. build-base-*-jenkins-agent.sh)
docker buildx build --load \
  --build-arg BASE_IMAGE=localhost/onec-client-s6 \
  --build-arg BASE_TAG=${ONEC_VERSION} \
  -t localhost/onec-client-vnc:${ONEC_VERSION} \
  -f client-vnc/Dockerfile .
```

## Клиент с дополнительными языками

[(Наверх)](#оглавление)

```bash
docker buildx build --load \
  --build-arg ONEC_USERNAME=${ONEC_USERNAME} \
  --build-arg ONEC_PASSWORD=${ONEC_PASSWORD} \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  --build-arg nls_enabled=true \
  -t localhost/onec-client-nls:${ONEC_VERSION} \
  -f client/Dockerfile .
```

## Тонкий клиент

[(Наверх)](#оглавление)

```bash
docker buildx build --load \
  --build-arg ONEC_USERNAME=${ONEC_USERNAME} \
  --build-arg ONEC_PASSWORD=${ONEC_PASSWORD} \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/onec-thin-client:${ONEC_VERSION} \
  -f thin-client/Dockerfile .
```

## Тонкий клиент с дополнительными языками

[(Наверх)](#оглавление)

```bash
docker buildx build --load \
  --build-arg ONEC_USERNAME=${ONEC_USERNAME} \
  --build-arg ONEC_PASSWORD=${ONEC_PASSWORD} \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  --build-arg nls_enabled=true \
  -t localhost/onec-thin-client-nls:${ONEC_VERSION} \
  -f thin-client/Dockerfile .
```

## Хранилище конфигурации

[(Наверх)](#оглавление)

```bash
docker buildx build --load \
  --build-arg ONEC_USERNAME=${ONEC_USERNAME} \
  --build-arg ONEC_PASSWORD=${ONEC_PASSWORD} \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/onec-crs:${ONEC_VERSION} \
  -f crs/Dockerfile .
```

## rac-gui

[(Наверх)](#оглавление)

```bash
docker buildx build --load \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/onec-rac-gui:${ONEC_VERSION}-1.0.1 \
  -f rac-gui/Dockerfile .
```

## gitsync

[(Наверх)](#оглавление)

```bash
docker buildx build --load \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/gitsync:3.0.0 \
  -f gitsync/Dockerfile .
```

## oscript

[(Наверх)](#оглавление)

```bash
docker buildx build --load \
  -t localhost/oscript:latest \
  -f oscript/Dockerfile .
```

## vanessa-runner

[(Наверх)](#оглавление)

```bash
docker buildx build --load \
  -t localhost/runner:1.7.0 \
  -f vanessa-runner/Dockerfile .
```

## EDT

[(Наверх)](#оглавление)

```bash
docker buildx build --load \
    --build-arg ONEC_USERNAME=${ONEC_USERNAME} \
    --build-arg ONEC_PASSWORD=${ONEC_PASSWORD} \
    --build-arg EDT_VERSION=${EDT_VERSION} \
    -t localhost/edt:${EDT_VERSION} \
    -f edt/Dockerfile .
```

## Исполнитель

[(Наверх)](#оглавление)

```bash
./build-executor.sh
```

Собирать обязательно через запуск скрипта, так как в нём реализован безопасный проброс секретов в окружение сборки

## Локальное тестирование CI (act)

[(Наверх)](#оглавление)

Для локального тестирования GitHub Actions используется [nektos/act](https://github.com/nektos/act).

### Установка

```bash
brew install act
```

### Запуск отдельной задачи

```bash
# Экспорт переменных окружения (включая ONEC_USERNAME, ONEC_PASSWORD)
source .envrc

# Сборка одного образа (например, server)
act -j server push \
  --directory . \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest \
  --container-architecture linux/amd64 \
  --secret ONEC_USERNAME="$ONEC_USERNAME" \
  --secret ONEC_PASSWORD="$ONEC_PASSWORD" \
  --secret GITHUB_TOKEN="${DOCKER_PASSWORD}" \
  --concurrent-jobs 1
```

### Параметры

| Параметр | Назначение |
|---|---|
| `-j <job>` | Имя задачи из `build.yml`: `server`, `executor`, `edt-swarm-agent`, `edt-k8s-agent`, `oscript-swarm-agent`, `oscript-k8s-agent`, `base-swarm-coverage-agent`, `base-k8s-coverage-agent` |
| `-P ubuntu-latest=...` | Образ-раннер (medium-вариант совместим с большинством actions) |
| `--container-architecture linux/amd64` | Архитектура контейнера (требуется для совместимости со сборочными образами) |
| `--concurrent-jobs 1` | Обход бага конкурентности в act < 0.2.89 |
| `--secret GITHUB_TOKEN=...` | Токен для `docker login` в ghcr.io при пуше |
| `-n` | Dry-run: только проверка валидности workflow без реальной сборки |

### Публикация образов

При симуляции события `push` workflow публикует образы в реестр. Чтобы собрать только локально без пуша, используйте `pull_request`:

```bash
act -j server pull_request \
  --directory . \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest \
  --container-architecture linux/amd64 \
  --secret ONEC_USERNAME="$ONEC_USERNAME" \
  --secret ONEC_PASSWORD="$ONEC_PASSWORD" \
  --concurrent-jobs 1
```

### Известные особенности

- **act v0.2.88**: обязателен `--concurrent-jobs 1` из-за бага `concurrent map iteration and map write`
- **Artifacts**: предупреждение `Unable to get the ACTIONS_RUNTIME_TOKEN env variable` безвредно — влияет только на загрузку build-записей в GitHub
- **Secrets in ARG**: Dockerfile использует `ARG ONEC_PASSWORD`, что вызывает предупреждение Docker о секретах в build-args
- **free-disk-space**: pre-build шаг пытается очистить диск через `apt-get remove` и `docker image prune` — в контейнере act это может занимать лишнее время

## Toolbox-образы для distrobox

[(Наверх)](#оглавление)

Образы `edt-toolbox` и `client-toolbox` предназначены для использования с [distrobox](https://distrobox.it/) или [toolbx](https://containertoolbx.org/).
Они включают те же компоненты, что и обычные образы EDT/клиент, но построены на базе `quay.io/toolbx/ubuntu-toolbox` и содержат shim-ссылки для прозрачного вызова `docker`, `podman`, `flatpak` с хоста.

### Сборка CI (GitHub Actions)

Toolbox-образы интегрированы в общий модульный пайплайн `.github/workflows/build.yml` и управляются отдельными reusable workflows:

- `.github/workflows/build-client-toolbox.yml` — сборка `client-toolbox`
- `.github/workflows/build-edt-toolbox.yml` — сборка `edt-toolbox`

Каждый workflow собирает цепочку `oscript-downloader → toolbox-образ` через композитный action `build-image`. Публикация в `ghcr.io/<owner>/` и подпись cosign опциональны (управляются переменной `publish`).

Включение/выключение сборки контролируется переменными репозитория:

| Переменная | Назначение |
|---|---|
| `BUILD_CLIENT_TOOLBOX` | `!= 'false'` включает сборку client-toolbox |
| `BUILD_EDT_TOOLBOX` | `!= 'false'` включает сборку edt-toolbox |

Необходимые секреты репозитория:

| Секрет | Описание |
|---|---|
| `ONEC_USERNAME` | Логин на releases.1c.ru |
| `ONEC_PASSWORD` | Пароль на releases.1c.ru |

Необходимые переменные репозитория (Variables — опционально, используются defaults):

| Переменная | По умолчанию | Назначение |
|---|---|---|
| `ONEC_VERSION` | `8.5.1.1343` | Версия платформы 1С для client-toolbox |
| `EDT_VERSION` | `2025.2.6` | Версия EDT для edt-toolbox |
| `OPENJDK_VERSION` | `17` | Версия JDK для стадии установки EDT |

### Локальная сборка

```bash
# Загрузите переменные окружения
source .envrc

# Собрать client-toolbox
./build-client-toolbox.sh

# Собрать edt-toolbox
./build-edt-toolbox.sh

# Сборка + пуш в реестр
PUSH=true DOCKER_REGISTRY_URL=ghcr.io/<owner> ./build-edt-toolbox.sh
```

Для использования с distrobox после сборки через Docker:

```bash
# Скопировать образ из Docker-демона в хранилище Podman
podman pull docker-daemon:localhost/edt-toolbox:latest

# Создать и войти в контейнер
distrobox create --image localhost/edt-toolbox:latest --name edt-toolbox
distrobox enter edt-toolbox
```

### Проверка подписи образа

```bash
cosign verify --key cosign.pub ghcr.io/<owner>/edt-toolbox:latest
cosign verify --key cosign.pub ghcr.io/<owner>/client-toolbox:latest
```
