# Примеры сборки и наслаивания

Сборка через `./bake build <target>` (см. [AGENTS.md](./AGENTS.md) раздел Bake).

## Варианты сборки

| Назначение | Команда |
|---|---|
| Запуск 1С | `./bake build client` |
| 1С + OneScript | `./bake build client-vnc-oscript` |
| 1C Jenkins агент | `./bake build base-jenkins-agent-k8s` или `base-jenkins-agent-swarm` |
| 1C Jenkins агент с покрытием | `./bake build coverage-jenkins-agent-k8s` |
| EDT | `./bake build edt` |
| EDT Jenkins агент | `./bake build edt-agent-k8s` |
| OneScript Jenkins агент | `./bake build oscript-jenkins-agent-k8s` |
| Сервер хранилища + Apache | `./bake build crs-apache` |
| Toolbox (distrobox) | `./bake build client-toolbox` / `edt-toolbox` |
| Элемент.Скрипт | `./bake build elementscript` |
| GitSync | `./bake build gitsync` |
| Vanessa Runner | `./bake build vanessa-runner` |

## Полная сборка

```bash
./bake build default    # все цели
./bake build publish    # только публикуемые
```
