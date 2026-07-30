# Примеры сборки и наслаивания

Ниже список последовательно собираемых образов для различных целей. Каждый следующий слой собирается поверх предыдущего. Сборка — через `./bake build <target>` (см. [README.md](./README.md)).

Полный состав слоёв в каждой цепочке соответствует плану (графу зависимостей HCL):
```shell
./bake plan
```

## Запуск 1С

* [`client`](client/bake.hcl)
* [`s6-overlay (client-s6)`](s6-overlay/bake.hcl)
* [`client-vnc`](client-vnc/bake.hcl)

Сборка:
```shell
./bake build client-vnc
```

## 1С и OneScript

* [`client`](client/bake.hcl)
* [`s6-overlay (client-s6)`](s6-overlay/bake.hcl)
* [`client-vnc`](client-vnc/bake.hcl)
* [`oscript (client-vnc-oscript)`](oscript/bake.hcl)

Сборка:
```shell
./bake build client-vnc-oscript
```

## 1С + OneScript для запуска VA

* [`client`](client/bake.hcl)
* [`s6-overlay (client-s6)`](s6-overlay/bake.hcl)
* [`client-vnc`](client-vnc/bake.hcl)
* [`oscript (client-vnc-oscript)`](oscript/bake.hcl)
* [`jdk (client-vnc-oscript-jdk)`](jdk/bake.hcl)
* [`test-utils`](test-utils/bake.hcl)

Сборка:
```shell
./bake build test-utils
```

## 1C как Jenkins агент

* [`client`](client/bake.hcl)
* [`s6-overlay (client-s6)`](s6-overlay/bake.hcl)
* [`client-vnc`](client-vnc/bake.hcl)
* [`oscript (client-vnc-oscript)`](oscript/bake.hcl)
* [`jdk (client-vnc-oscript-jdk)`](jdk/bake.hcl)
* [`test-utils`](test-utils/bake.hcl)
* [`k8s-jenkins-agent  (base-jenkins-agent-k8s)`](k8s-jenkins-agent/bake.hcl) или [`swarm-jenkins-agent (base-jenkins-agent-swarm)`](swarm-jenkins-agent/bake.hcl)

Сборка:
```shell
./bake build base-jenkins-agent-k8s
./bake build base-jenkins-agent-swarm
```

## 1С + OneScript как Jenkins агент для запуска тестов

Полная цепочка слоёв, без сокращений:

* [`client`](client/bake.hcl)
* [`s6-overlay (client-s6)`](s6-overlay/bake.hcl)
* [`client-vnc`](client-vnc/bake.hcl)
* [`oscript (client-vnc-oscript)`](oscript/bake.hcl)
* [`jdk (client-vnc-oscript-jdk)`](jdk/bake.hcl)
* [`test-utils`](test-utils/bake.hcl)
* [`k8s-jenkins-agent (base-jenkins-agent-k8s)`](k8s-jenkins-agent/bake.hcl) или [`swarm-jenkins-agent (base-jenkins-agent-swarm)`](swarm-jenkins-agent/bake.hcl)

Сборка:
```shell
./bake build base-jenkins-agent-k8s
./bake build base-jenkins-agent-swarm
```

## EDT

* [`edt`](edt/bake.hcl)

Сборка:
```shell
./bake build edt
```

## EDT + s6 (промежуточный слой)

* [`edt`](edt/bake.hcl)
* [`s6-overlay (edt-s6)`](s6-overlay/bake.hcl)

Сборка:
```shell
./bake build edt-s6
```

## EDT Toolbox (distrobox)

* [`client-toolbox (toolbox)`](client/bake.hcl)
* [`edt-toolbox (toolbox)`](edt/bake.hcl)
* [`edt-toolbox-client (base)`](edt/bake.hcl)

Сборка:
```shell
./bake build edt-toolbox-client
```

## EDT как Jenkins агент

* [`edt`](edt/bake.hcl)
* [`s6-overlay (edt-s6)`](s6-overlay/bake.hcl)
* [`k8s-jenkins-agent (edt-agent-k8s)`](k8s-jenkins-agent/bake.hcl) или [`swarm-jenkins-agent (edt-agent-swarm)`](swarm-jenkins-agent/bake.hcl)

Сборка:
```shell
./bake build edt-agent-k8s
./bake build edt-agent-swarm
```

## OneScript как Jenkins агент

* [`oscript-jdk (поверх eclipse-temurin:17)`](oscript/bake.hcl)
* [`s6-overlay (oscript-jdk-s6)`](s6-overlay/bake.hcl)
* [`k8s-jenkins-agent (oscript-jenkins-agent-k8s)`](k8s-jenkins-agent/bake.hcl) или [`swarm-jenkins-agent (oscript-jenkins-agent-swarm)`](swarm-jenkins-agent/bake.hcl)

Сборка:
```shell
./bake build oscript-jenkins-agent-k8s
./bake build oscript-jenkins-agent-swarm
```

## Сервер хранилища + Apache

* [`crs`](crs/bake.hcl)
* [`crs-apache`](crs-apache/bake.hcl)

```shell
./bake build crs-apache
```

## Полная сборка

```bash
./bake build default    # все цели
./bake build publish    # только публикуемые
```
