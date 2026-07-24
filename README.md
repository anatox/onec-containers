# onec-containers

[![forthebadge](http://forthebadge.com/images/badges/built-with-love.svg)](http://forthebadge.com)

В данном репозитории находятся файлы для самостоятельной сборки образов [Docker](https://www.docker.com) с платформой [1С:Предприятие](http://v8.1c.ru) 8. Также есть отдельные образы для запуска на [Distrobox](https://distrobox.it).

## Оглавление

<!-- TOC -->

- [Использование](#использование)
  - [Настройка GitHub Actions](#настройка-github-actions)
  - [Подпись образов через Cosign](#подпись-образов-через-cosign)
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

### Настройка GitHub Actions

Версии компонентов задаются в `bakery/versions.hcl`.

В зависимости от видимости репозитория настройте секреты в Settings → Secrets and variables → Actions:

**Приватный репозиторий** (рекомендуется) — сборки приватны по умолчанию, пакеты наследуют видимость репо:

| Секрет | Назначение |
|---|---|
| `ONEC_USERNAME` | Учётная запись на [releases.1c.ru](https://releases.1c.ru) |
| `ONEC_PASSWORD` | Пароль для учётной записи |
| `ELEMENTSCRIPT_DOWNLOAD_KEY` | Токен для скачивания Element.Script с [developer.1c.ru](https://developer.1c.ru) |

**Публичный репозиторий** — требуется PAT во избежание утечки приватных пакетов в публичный доступ:

| Секрет | Назначение |
|---|---|
| `ONEC_USERNAME` | Учётная запись на [releases.1c.ru](https://releases.1c.ru) |
| `ONEC_PASSWORD` | Пароль для учётной записи |
| `ELEMENTSCRIPT_DOWNLOAD_KEY` | Токен для скачивания Element.Script с [developer.1c.ru](https://developer.1c.ru) |
| `GHCR_PUSH_TOKEN` | **Обязательно.** Classic PAT с правами `write:packages` и `delete:packages`. `GITHUB_TOKEN` создаёт публичные пакеты в публичном репо — workflow упадёт с ошибкой без этого секрета. |

Создайте [classic PAT](https://github.com/settings/tokens/new) с правами `write:packages` и используйте как секрет `GHCR_PUSH_TOKEN`.

### Подпись образов через Cosign

Workflow автоматически подписывает образы через [Cosign](https://docs.sigstore.dev) (keyless-подпись через OIDC/Fulcio/Rekor). Дополнительная настройка не требуется.

Проверка подписи:

```bash
cosign verify \
  --certificate-identity "https://github.com/<owner>/<repo>/.github/workflows/build.yml@refs/heads/main" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/<owner>/<image>:<tag>
```

## Локальная сборка

В терминале введите:

```bash
$ cp .envrc.example .envrc
```

Скорректируйте `.envrc`, указав учётные данные и registry:

- `ONEC_USERNAME` — учётная запись на [releases.1c.ru](https://releases.1c.ru)
- `ONEC_PASSWORD` — пароль для учётной записи
- `CONTAINER_REGISTRY_URL` — адрес container-registry для публикации образов
- `ELEMENTSCRIPT_DOWNLOAD_KEY` — токен для API [developer.1c.ru](https://developer.1c.ru)

Загрузите переменные (`direnv allow` при использовании [direnv](https://direnv.net/)):

```bash
source .envrc
```

Сборка:

```bash
./bake build server     # один образ
./bake build default    # все образы
REGISTRY_PREFIX=ghcr.io/user ./bake build server -- --push  # публикация
```

## Devcontainer

Проект включает конфигурацию [devcontainer](https://containers.dev) для локальной разработки (`.devcontainer/`):

При открытии проекта, VS Code предложит переоткрыть в контейнере → "Reopen in Container". Также можно набрать в палитре команд:

```
> Dev Containers: Reopen in Container
```

Devcontainer предоставляет:
- Docker-in-Docker для сборки образов через `docker buildx bake`
- Python 3 для `./bake` и `bakery/select.py`
- Установку direnv и автозагрузку `.envrc`
- Необходимые системные пакеты (bash, git, jq)

Файл `.devcontainer/devcontainer.json` описывает образ, фичи и postCreate-скрипт.

## Как использовать готовые дистрибутивы

Вы можете использовать готовые дистрибутивы платформы, для этого достаточно разместить их в папке `distr`. Скрипты будут автоматически использовать их для сборки образа. Доступно только при локальном запуске.

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
./bake build server
```

## Клиент

[(Наверх)](#оглавление)

```bash
./bake build client
```

## Клиент с поддержкой VNC

[(Наверх)](#оглавление)

```bash
./bake build client-vnc
```

## Тонкий клиент

[(Наверх)](#оглавление)

```bash
./bake build thin-client
```

## Хранилище конфигурации

[(Наверх)](#оглавление)

```bash
./bake build crs
```

## gitsync

[(Наверх)](#оглавление)

```bash
./bake build gitsync
```

## oscript

[(Наверх)](#оглавление)

```bash
./bake build oscript
```

## vanessa-runner

[(Наверх)](#оглавление)

```bash
./bake build vanessa-runner
```

## EDT

[(Наверх)](#оглавление)

```bash
./bake build edt
```

## Элемент.Скрипт (Исполнитель)

[(Наверх)](#оглавление)

```bash
./bake build elementscript
```

## Toolbox-образы для distrobox

[(Наверх)](#оглавление)

Образы `edt-toolbox` и `client-toolbox` предназначены для использования с [distrobox](https://distrobox.it/) или [toolbx](https://containertoolbx.org/).

```bash
./bake build client-toolbox      # 1С клиент + toolbox
./bake build edt-toolbox         # EDT + toolbox
./bake build edt-toolbox-client  # EDT + 1С клиент + toolbox
```

Для использования с distrobox после сборки:

```bash
distrobox create --image localhost/edt-toolbox:local --name edt-toolbox
distrobox enter edt-toolbox
```
