# onec-containers

[![forthebadge](http://forthebadge.com/images/badges/built-with-love.svg)](http://forthebadge.com)

В данном репозитории находятся файлы для сборки образов OCI-контейнеров с платформой [1С:Предприятие](http://v8.1c.ru) 8.3.

## Оглавление

<!-- TOC -->

- [Описание](#описание)
  - [Оглавление](#оглавление)
  - [Использование](#использование)
  - [Сборка через git-теги CI](#сборка-через-git-теги-ci)
    - [Формат тегов](#формат-тегов)
    - [Примеры](#примеры)
    - [Гигиена локального клона](#гигиена-локального-клона)
  - [Локальная сборка](#локальная-сборка)
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
  - [Локальное тестирование CI act](#локальное-тестирование-ci-act)
    - [Установка](#установка)
    - [Запуск отдельной задачи](#запуск-отдельной-задачи)
    - [Параметры](#параметры)
    - [Публикация образов](#публикация-образов)
    - [Известные особенности](#известные-особенности)
  - [Toolbox-образы для distrobox](#toolbox-образы-для-distrobox)
    - [Сборка CI GitHub Actions](#сборка-ci-github-actions)
    - [Локальная сборка Toolbox-образов](#локальная-сборка-toolbox-образов)
    - [Проверка подписи образа](#проверка-подписи-образа)

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
Используется при сборке агента скриптами `build-base-*-jenkins-coverage-agent.*`.
- DEV1C_EXECUTOR_API_KEY - токен для api скачивания 1С:Исполнитель с сайта developer.1c.ru
- EXECUTOR_VERSION - версия 1С:Исполнитель для сборки
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

## Сборка через git-теги (CI)

Самый простой способ запустить сборку конкретного пакета — пушнуть git-тег в формате:

```
packages/<component>/v<version>
```

Тег резолвится в следующий номер сборки `-rN` (всегда инкрементируется), собирается образ, и plain-тег удаляется с origin. На origin остаются только immutable `-rN` теги.

### Формат тегов

| Компонент | Тег | Собираемые образы |
|---|---|---|
| `server` | `packages/server/v8.5.1.1343` | `onec-server:8.5.1.1343-r1` |
| `executor` | `packages/executor/v7.0.3.3` | `executor:7.0.3.3-r1` |
| `client-toolbox` | `packages/client-toolbox/v8.5.1.1343` | `client-toolbox:8.5.1.1343-r1` |
| `edt-agent` | `packages/edt-agent/v2025.2.6` | `edt`, `edt-s6`, `edt-agent` → `2025.2.6-r1` |
| `edt-agent-k8s` | `packages/edt-agent-k8s/v2025.2.6` | то же для k8s |
| `oscript-agent` | `packages/oscript-agent/v2.0.2` | `oscript-jdk`, `oscript-jdk-s6`, `oscript-agent` → `2.0.2-r1` |
| `oscript-agent-k8s` | `packages/oscript-agent-k8s/v2.0.2` | то же для k8s |
| `coverage-agent` | `packages/coverage-agent/v8.5.1.1343` | `base-jenkins-coverage-agent:8.5.1.1343-r1` |
| `coverage-agent-k8s` | `packages/coverage-agent-k8s/v8.5.1.1343` | то же для k8s |
| `edt-toolbox` | `packages/edt-toolbox/v2025.2.6-client8.5.1.1343` | `edt-toolbox:2025.2.6-base-r1` + `edt-toolbox:2025.2.6-client8.5.1.1343-r1` |
| `edt-toolbox` | `packages/edt-toolbox/v2025.2.6` | `edt-toolbox:2025.2.6-base-r1` (только EDT) |

### Примеры

```bash
# Первая сборка сервера 8.5.1.1343
git tag packages/server/v8.5.1.1343
git push origin packages/server/v8.5.1.1343
# → строится onec-server:8.5.1.1343-r1, тег -r1 остаётся на origin

# Следующая сборка той же версии (тот же самый git push)
git push origin packages/server/v8.5.1.1343
# → строится onec-server:8.5.1.1343-r2

# Явная сборка с конкретным номером
git tag packages/server/v8.5.1.1343-r5
git push origin packages/server/v8.5.1.1343-r5
# → onec-server:8.5.1.1343-r5, тег остаётся на origin без изменений

# EDT toolbox с клиентом
git tag packages/edt-toolbox/v2025.2.6-client8.5.1.1343
git push origin packages/edt-toolbox/v2025.2.6-client8.5.1.1343
# → edt-toolbox:2025.2.6-base-r1 + edt-toolbox:2025.2.6-client8.5.1.1343-r1
```

### Гигиена локального клона

После сборки plain-тег удаляется с origin, но остаётся в локальном клоне (`git fetch` не чистит теги по умолчанию). Это безвредно — следующий `git push` тега просто пересоздаст его на origin, что означает "собрать ещё раз". Для очистки: `git fetch --prune --tags origin`.

## Локальная сборка

:point_up: Запустите последовательно скрипты для сборки образов. Для публикации в реестр передайте `PUSH=true CONTAINER_REGISTRY_URL=<registry>`.

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
buildah build \
  --secret=id=onec_username,env=ONEC_USERNAME \
  --secret=id=onec_password,env=ONEC_PASSWORD \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/onec-server:${ONEC_VERSION} \
  -f server/Containerfile .
```

## Сервер с дополнительными языками

[(Наверх)](#оглавление)

```bash
buildah build \
  --secret=id=onec_username,env=ONEC_USERNAME \
  --secret=id=onec_password,env=ONEC_PASSWORD \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  --build-arg NLS_ENABLED=true \
  -t localhost/onec-server-nls:${ONEC_VERSION} \
  -f server/Containerfile .
```

## Клиент

[(Наверх)](#оглавление)

```bash
buildah build \
  --secret=id=onec_username,env=ONEC_USERNAME \
  --secret=id=onec_password,env=ONEC_PASSWORD \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/onec-client:${ONEC_VERSION} \
  -f client/Containerfile .
```

## Клиент с поддержкой VNC

[(Наверх)](#оглавление)

```bash
# Предварительно соберите onec-client и onec-client-s6 (см. build-base-*-jenkins-agent.sh)
buildah build \
  --build-arg BASE_IMAGE=localhost/onec-client-s6 \
  --build-arg BASE_TAG=${ONEC_VERSION} \
  -t localhost/onec-client-vnc:${ONEC_VERSION} \
  -f client-vnc/Containerfile .
```

## Клиент с дополнительными языками

[(Наверх)](#оглавление)

```bash
buildah build \
  --secret=id=onec_username,env=ONEC_USERNAME \
  --secret=id=onec_password,env=ONEC_PASSWORD \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  --build-arg NLS_ENABLED=true \
  -t localhost/onec-client-nls:${ONEC_VERSION} \
  -f client/Containerfile .
```

## Тонкий клиент

[(Наверх)](#оглавление)

```bash
buildah build \
  --secret=id=onec_username,env=ONEC_USERNAME \
  --secret=id=onec_password,env=ONEC_PASSWORD \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/onec-thin-client:${ONEC_VERSION} \
  -f thin-client/Containerfile .
```

## Тонкий клиент с дополнительными языками

[(Наверх)](#оглавление)

```bash
buildah build \
  --secret=id=onec_username,env=ONEC_USERNAME \
  --secret=id=onec_password,env=ONEC_PASSWORD \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  --build-arg NLS_ENABLED=true \
  -t localhost/onec-thin-client-nls:${ONEC_VERSION} \
  -f thin-client/Containerfile .
```

## Хранилище конфигурации

[(Наверх)](#оглавление)

```bash
buildah build \
  --secret=id=onec_username,env=ONEC_USERNAME \
  --secret=id=onec_password,env=ONEC_PASSWORD \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/onec-crs:${ONEC_VERSION} \
  -f crs/Containerfile .
```

## rac-gui

[(Наверх)](#оглавление)

```bash
buildah build \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/onec-rac-gui:${ONEC_VERSION}-1.0.1 \
  -f rac-gui/Containerfile .
```

## gitsync

[(Наверх)](#оглавление)

```bash
buildah build \
  --build-arg ONEC_VERSION=${ONEC_VERSION} \
  -t localhost/gitsync:3.0.0 \
  -f gitsync/Containerfile .
```

## oscript

[(Наверх)](#оглавление)

```bash
buildah build \
  -t localhost/oscript:latest \
  -f oscript/Containerfile .
```

## vanessa-runner

[(Наверх)](#оглавление)

```bash
buildah build \
  -t localhost/runner:1.7.0 \
  -f vanessa-runner/Containerfile .
```

## EDT

[(Наверх)](#оглавление)

```bash
buildah build \
    --secret=id=onec_username,env=ONEC_USERNAME \
    --secret=id=onec_password,env=ONEC_PASSWORD \
    --build-arg EDT_VERSION=${EDT_VERSION} \
    -t localhost/edt:${EDT_VERSION} \
    -f edt/Containerfile .
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
# Экспорт переменных окружения (без использования direnv)
source .envrc

# Сборка одного образа (например, server)
act -j server push \
  --directory . \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest \
  --container-architecture linux/amd64 \
  --secret ONEC_USERNAME="$ONEC_USERNAME" \
  --secret ONEC_PASSWORD="$ONEC_PASSWORD" \
  --secret GITHUB_TOKEN="$(gh auth token)" \
  --concurrent-jobs 1
```

### Параметры

| Параметр | Назначение |
|---|---|
| `-j <job>` | Имя workflow: `server`, `executor`, `edt-swarm-agent`, `edt-k8s-agent`, `oscript-swarm-agent`, `oscript-k8s-agent`, `base-swarm-coverage-agent`, `base-k8s-coverage-agent` |
| `-P ubuntu-latest=...` | Образ-раннер (medium-вариант совместим с большинством actions) |
| `--container-architecture linux/amd64` | Архитектура контейнера (требуется для совместимости со сборочными образами) |
| `--concurrent-jobs 1` | Обход бага конкурентности в act < 0.2.89 |
| `--secret GITHUB_TOKEN=...` | Токен для `podman login` в ghcr.io при пуше |
| `-n` | Dry-run: только проверка валидности workflow без реальной сборки |

### Публикация образов

При симуляции события `push` workflow публикует образы в реестр. Чтобы собрать только локально без пуша, используйте `workflow_dispatch`:

```bash
act -j server workflow_dispatch \
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
- **Secrets**: Данные учётной записи 1С передаются через `--secret` (buildah build) или `--mount=type=secret` (Containerfile), не попадая в слои образа
- **free-disk-space**: pre-build шаг пытается очистить диск через `apt-get remove` и `docker image prune` — в контейнере act это может занимать лишнее время

## Toolbox-образы для distrobox

[(Наверх)](#оглавление)

Образы `edt-toolbox` и `client-toolbox` предназначены для использования с [distrobox](https://distrobox.it/) или [toolbx](https://containertoolbx.org/).
Они включают те же компоненты, что и обычные образы EDT/клиент, но построены на базе `quay.io/toolbx/ubuntu-toolbox` и содержат shim-ссылки для прозрачного вызова `docker`, `podman`, `flatpak` с хоста.

### Сборка CI (GitHub Actions)

Toolbox-образы собираются через отдельные workflows, запускаемые по git-тегам:

- `.github/workflows/build-client-toolbox.yml` — сборка `client-toolbox` (тег `packages/client-toolbox/v*`)
- `.github/workflows/build-edt-toolbox.yml` — сборка `edt-toolbox` (тег `packages/edt-toolbox/v*`)

Каждый workflow собирает цепочку `oscript-downloader → toolbox-образ` через композитный action `build-image`. Публикация в `ghcr.io/<owner>/` и подпись cosign опциональны (управляются через тег или параметр `publish` в `workflow_dispatch`).

Для PR в `main` сборка автоматически проверяется (без публикации). Включение/выключение PR-сборки контролируется переменными репозитория:

| Переменная | Назначение |
|---|---|
| `BUILD_CLIENT_TOOLBOX` | `!= 'false'` включает сборку client-toolbox |
| `BUILD_EDT_TOOLBOX` | `!= 'false'` включает сборку edt-toolbox |

Необходимые секреты репозитория:

| Секрет | Описание |
|---|---|
| `ONEC_USERNAME` | Логин на releases.1c.ru |
| `ONEC_PASSWORD` | Пароль на releases.1c.ru |

Необходимые переменные репозитория (Variables — опционально, используются defaults из workflow):

| Переменная | Назначение |
|---|---|
| `BUILD_CLIENT_TOOLBOX` | `!= 'false'` включает PR-сборку client-toolbox |
| `BUILD_EDT_TOOLBOX` | `!= 'false'` включает PR-сборку edt-toolbox |

Workflow defaults для версий (используются при `pull_request` и `workflow_dispatch` без явного указания):

| Компонент | Значение по умолчанию |
|---|---|
| Платформа 1С | `8.5.1.1343` |
| EDT | `2025.2.6` |
| OneScript | `2.0.2` |
| Executor | `7.0.3.3` |

### Локальная сборка Toolbox-образов

```bash
# Экспорт переменных окружения (без использования direnv)
source .envrc

# Сборка client-toolbox
./build-client-toolbox.sh

# Сборка edt-toolbox
./build-edt-toolbox.sh

# Сборка + пуш в реестр
PUSH=true CONTAINER_REGISTRY_URL=ghcr.io/<owner> ./build-edt-toolbox.sh
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
