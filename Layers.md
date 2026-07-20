# Примеры сборки и наслаивания

Сборка через `scripts/bake.py <target>` (см. [AGENTS.md](./AGENTS.md) раздел Bake).

## Варианты сборки

| Назначение | Команда |
|---|---|
| Запуск 1С | `scripts/bake.py client` |
| 1С + OneScript | `scripts/bake.py client-vnc-oscript` |
| 1C Jenkins агент | `scripts/bake.py base-jenkins-agent-k8s` или `base-jenkins-agent-swarm` |
| 1C Jenkins агент с покрытием | `scripts/bake.py coverage-agent-k8s` |
| EDT | `scripts/bake.py edt` |
| EDT Jenkins агент | `scripts/bake.py edt-agent-k8s` |
| OneScript Jenkins агент | `scripts/bake.py oscript-agent-k8s` |
| Сервер хранилища + Apache | `scripts/bake.py crs-apache` |
| Toolbox (distrobox) | `scripts/bake.py client-toolbox` / `edt-toolbox` |
| Элемент.Скрипт | `scripts/bake.py elementscript` |
| GitSync | `scripts/bake.py gitsync` |
| Vanessa Runner | `scripts/bake.py vanessa-runner` |

## Полная сборка

```bash
scripts/bake.py default    # все 32 цели
scripts/bake.py publish    # только публикуемые (24)
```
