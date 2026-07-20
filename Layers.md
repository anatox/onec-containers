# Примеры сборки и наслаивания

Сборка через `./bake.py <target>` (см. [AGENTS.md](./AGENTS.md) раздел Bake).

## Варианты сборки

| Назначение | Команда |
|---|---|
| Запуск 1С | `./bake.py client` |
| 1С + OneScript | `./bake.py client-vnc-oscript` |
| 1C Jenkins агент | `./bake.py base-jenkins-agent-k8s` или `base-jenkins-agent-swarm` |
| 1C Jenkins агент с покрытием | `./bake.py coverage-jenkins-agent-k8s` |
| EDT | `./bake.py edt` |
| EDT Jenkins агент | `./bake.py edt-agent-k8s` |
| OneScript Jenkins агент | `./bake.py oscript-jenkins-agent-k8s` |
| Сервер хранилища + Apache | `./bake.py crs-apache` |
| Toolbox (distrobox) | `./bake.py client-toolbox` / `edt-toolbox` |
| Элемент.Скрипт | `./bake.py elementscript` |
| GitSync | `./bake.py gitsync` |
| Vanessa Runner | `./bake.py vanessa-runner` |

## Полная сборка

```bash
./bake.py default    # все цели
./bake.py publish    # только публикуемые
```
