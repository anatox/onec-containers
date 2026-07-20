# 1C:Enterprise container images

Build system: `docker buildx bake` with HCL configuration. Targets in `*/bake.hcl` alongside Dockerfiles, shared variables/functions/groups in `bake/`. Inter-image dependencies via named contexts. Selector (`scripts/bake-select.py`) computes affected-closure from git diff and context graph.

## Bake

### HCL File Layout

Three shared files in `bake/` + `*/bake.hcl` in every directory with a Dockerfile:
- Shared: `bake/versions.hcl` (variables), `bake/common.hcl` (functions), `bake/groups.hcl` (default/publish groups)
- `scripts/bake.py` — auto-discovers `bake/*.hcl` + `*/bake.hcl`, passes explicit `-f` flags (avoids bake's compose trap)
- All HCL files are merged before evaluation — variables/functions from one file are visible in others
- `--print` writes JSON to stdout, progress to stderr; piping requires `2>/dev/null`

### HCL: capabilities and limitations

- `split/slice/length/join` for strings — reliable; `for`-expressions work: `[for p in parts : f(p)]`
- `regex_replace` — escaping is unreliable in bake, avoid; use `split/slice/join` instead
- User functions can call other user functions; cannot be called from `variable` blocks
- No function overloading or optional parameters; use separate functions for variants (`tags`, `tags_full`)
- No runtime type-detection (`is_list`, etc.)
- `variable` default can reference stdlib functions and other variables, but not user functions

### Named Context Rule

The context key must **exactly match** the ARG default in the Dockerfile. Since all Dockerfiles use `localhost/<image>:local` as the FROM-arg default, contexts resolve without Dockerfile edits:

```hcl
# Dockerfile has ARG INSTALLER_IMAGE=localhost/onec-installer:local
contexts = {"localhost/onec-installer:local" = "target:installer"}
```

For overlays with a bare ARG (s6-overlay, jdk, test-utils, agents):
```hcl
args = {BASE_IMAGE = "localhost/onec-client:local"}
contexts = {"localhost/onec-client:local" = "target:client"}
```
Resolution: context key matches against any tag of the target (not just a specific one).

### Multi-stage Dockerfile for variant targets

A single Dockerfile can serve multiple bake targets via named stages:
```hcl
target "client"           { target = "client" }
target "client-toolbox"   { target = "toolbox", args = { BASE_IMAGE = "quay.io/…" } }
target "edt-toolbox"      { target = "toolbox" }
target "edt-toolbox-client" { dockerfile = "client/Dockerfile", target = "base" }
```
Overlay targets (s6-overlay, jdk, test-utils) are defined at the consumer, not in the snippet directory.

### Tag Scheme

- Local: `localhost/<image>:local`, `localhost/<image>:<version>`, `localhost/<image>:<short>` (short = `shortver(version)`)
- CI (REGISTRY_PREFIX + GIT_SHA): additionally `<prefix>/<image>:<version>`, `<prefix>/<image>:<short>`, `<prefix>/<image>:<version>-g<sha7>`
- CI + PUBLISH_LATEST: also `<prefix>/<image>:latest`
- **Agents** — platform-agnostic repo name (`base-jenkins-agent`, `edt-agent`, `oscript-agent`), platform in tag:
  - `localhost/<agent>:local-<k8s|swarm>`, `:<version>-<k8s|swarm>`, `:<short>-<k8s|swarm>`
  - Floating (replaces latest): `:<k8s|swarm>`

### Labels

- `onec.image` = registry repo name (mandatory, all targets)
- `onec.skip-publish = "true"` = intermediate target, excluded from publish matrix via `group "publish"` in `bake/groups.hcl`
- `onec.extra-srcs = "<prefix>,<prefix>"` = cross-dir inputs (COPY from scripts/, other directories) — selector matches these prefixes when finding affected targets. Stored in HCL via `description = jsonencode({"extra-srcs" = [...]})`

### Adding a new target — checklist

1. Dockerfile in its own directory, `ARG BASE_IMAGE=localhost/<dep>:local` (or `ARG INSTALLER_IMAGE=...`)
2. `*/bake.hcl`: target block with `dockerfile`, `contexts`, `args`, `tags`, `labels`, `cache_from`, `cache_to`
3. `onec.extra-srcs` for all cross-dir COPY (scripts/, other directories) — via `description = jsonencode({"extra-srcs" = [...]})`
4. `bake/groups.hcl`: add to `group "default"`; to `group "publish"` if not skip-publish
5. `scripts/bake-select.py` — self-test: re-run `--self-test` (add a case if new edge topology)
6. Verify: `scripts/bake.py --print | python3 scripts/bake-select.py --plan - --changed <new>/Dockerfile` → non-empty build-set

### Selector

`scripts/bake-select.py` — stdlib-only Python, computes affected-closure:

```bash
scripts/bake.py --print > bake-plan.json
python3 scripts/bake-select.py --plan bake-plan.json --git-range HEAD~1..HEAD --github-output
```

Logic:
1. `dirname(dockerfile)` → directory-to-targets mapping
2. `onec.extra-srcs` → path-prefix-to-targets mapping
3. Reverse graph from `contexts` values of `target:<dep>`
4. Changed files → seeds → transitive closure of dependents
5. Global build-all paths: `bake/`, `scripts/bake.py`, `.dockerignore`, `scripts/bake-select.py`, `.github/`
6. Publish partition: filter out `onec.skip-publish`

### CI

`.github/workflows/bake.yml`:
- `push`: plan job (checkout depth 0 → `--git-range`) → build matrix per published target
- `workflow_dispatch`: `--all` (or `--pattern`)
- Secrets: `ONEC_USERNAME`, `ONEC_PASSWORD`, `ELEMENTSCRIPT_DOWNLOAD_TOKEN`, `COSIGN_PRIVATE_KEY`

### Compose

- `compose.dev.yaml`: developer runtime stack (srv/db/repo/ras/client), images reference `${CONTAINER_REGISTRY_URL:-localhost}/...:${ONEC_VERSION:-local}`
- `compose.bake.yaml`: registry:2 helper for E2E testing of publish/cache
- `COMPOSE_FILE=compose.dev.yaml` in `.envrc.example`

### Limitations (by design)

- COPY parsing is not done: `onec.extra-srcs` is a manual escape hatch for cross-dir inputs

## Project Overview

This repository contains container configurations for 1C:Enterprise (1С:Предприятие) 8.3+, a popular Russian ERP and business automation platform. The project provides containerized solutions for various 1C components including servers, clients, development tools, and CI/CD agents.

## Key Technologies and Patterns

### Core Technologies

- **buildx bake**: image builds via HCL configuration with named contexts
- **Compose**: orchestration for local development
- **1C:Enterprise Platform 8**
- **OneScript (oscript)**: scripting language for 1C automation
- **EDT (Enterprise Development Tools)**: 1C development environment
- **Vanessa Runner**: testing framework for 1C
- **Element Script**: 1C:Enterprise Element.Script runtime
- **Jenkins**: CI/CD agents in containers

### Languages and Scripts

- **Dockerfile**: container definitions
- **HCL**: bake build configuration (`*/bake.hcl`)
- **Python**: bake-select.py, bake.py (~400 lines)
- **Russian language**: documentation, examples, comments and commit messages are primarily in Russian
- **AGENTS.md** is in English (unlike other docs which use Russian)

## Repository Structure

### Container Images Organization

Each directory is a specific image:

- `server/`: 1C:Enterprise server
- `client/`: 1C:Enterprise thick client (+ `client-toolbox` via multi-stage)
- `thin-client/`: 1C:Enterprise thin client
- `edt/`: Enterprise Development Tools (+ `edt-toolbox`, `edt-toolbox-client` via multi-stage)
- `oscript/`: OneScript runtime (+ `oscript-jdk`, `oscript-jdk-s6`, `client-vnc-oscript`, `vanessa-automation`)
- `vanessa-runner/`: testing framework
- `swarm-jenkins-agent/` and `k8s-jenkins-agent/`: CI/CD agents (base, edt, oscript)
- `coverage41C/`: code coverage tools
- `s6-overlay/`: s6-overlay mod snippet (overlay, targets at consumers)
- `jdk/`: OpenJDK mod snippet (overlay)
- `test-utils/`: vanessa-automation overlay snippet (apt deps + opm toolset)
- `client-vnc/`: VNC-enabled client image

### Build System

- `scripts/bake.py --print default publish`: build all targets
- `scripts/bake-select.py --plan <json> --git-range <range>`: affected-only build
- Local development: `.devcontainer/`

## Dockerfile Guidelines

1. **Multi-stage builds**: use for downloading/building dependencies
2. **Secrets**: `RUN --mount=type=secret,id=secrets_env`, source file inside Dockerfile
3. **ARG variables**: standard pattern:
   ```dockerfile
   ARG ONEC_VERSION
   ARG BASE_IMAGE=ubuntu:26.04
   FROM ${BASE_IMAGE}
   ```
4. **Labels**: `onec.image` mandatory, `org.opencontainers.image.authors`
5. **Layer optimization**: combine RUN commands

### Environment Variables

- `ONEC_USERNAME`, `ONEC_PASSWORD`: access to releases.1c.ru
- `ONEC_VERSION`: 1C platform version (8.x.x.xxxx)
- `EDT_VERSION`: EDT version
- `CONTAINER_REGISTRY_URL`: container registry URL
  - `ELEMENTSCRIPT_DOWNLOAD_TOKEN`, `ELEMENTSCRIPT_VERSION`: 1C:Enterprise Element.Script

## Security and Credentials

- Never hardcode credentials in Dockerfiles or scripts
- Use `--mount=type=secret` for sensitive data, not ARG/ENV
- Build args only for non-sensitive config (`ONEC_VERSION`, `CONTAINER_REGISTRY_URL`)
- Configuration examples in `.example` files

## Architecture

- Every image has a Dockerfile in its own directory and a `bake.hcl` with a target block
- **`scripts/installer/` — the `onec-install` toolchain**: `bin/onec-install` → `libexec/`
- **Image naming**: `localhost/<name>:<tag>` locally, `<prefix>/<name>:<tag>` in CI
- **Toolbox images**: `quay.io/toolbx/ubuntu-toolbox:26.04` base instead of `ubuntu:26.04`, distrobox shims for host-forwarding

## Image Layering

- Toolchain for all 1C components: `oscript → installer`
- Agent chain: `client → s6-overlay → client-vnc → oscript → jdk → test-utils → base-jenkins-agent`
- Coverage agent: `base-jenkins-agent + EDT` (JAR extraction)
- OScript agent: `eclipse-temurin:17 → oscript → s6-overlay → oscript-agent`
- `s6-overlay` is always a layer between app and agent
- `client-toolbox` merged into `client/Dockerfile` (multi-stage), EDT toolbox client in `edt/Dockerfile`
- Containers reference base images with single `BASE_IMAGE=<name>:<tag>`

## Non-Obvious Dependencies

- PostgreSQL: `rsyuzyov/docker-postgresql-pro-1c` (third-party image with 1C-compatible extensions)
- RAS reuses server image: entrypoint override → `/opt/1cv8/current/ras`
- `gitsync`: COPY --from phase-2 client + oscript base

## Key Workarounds

- 1C ships its own `libstdc++` (`client-vnc/Dockerfile`) — must be removed before runtime (GLIBCXX/GCC crash)
- EDT pre-2025 requires full JDK with JavaFX. EDT <= 2023: Java 11, EDT 2024: Java 17, EDT >= 2025: bundled Axiom JDK
- `iptables` must be held in s6-overlay and VNC images
- Xfce in containers: `NO_AT_BRIDGE=1`, `QT_X11_NO_MITSHM=1`, `xfce4-panel --disable-wm-check`

## Documentation Standards

- Use Russian for 1C-specific terminology
- English translations for common international concepts
- When rewriting source files, preserve existing section comments

## Common Patterns to Follow

### Container Naming

- **Platform images**: `onec-<component>:${VERSION}`, `onec-client:${VERSION}`
- **EDT**: `edt:${EDT_VERSION}`, `edt-s6:${EDT_VERSION}`, `edt-agent:${EDT_VERSION}`
- **Toolbox**: `edt-toolbox:${EDT_VERSION}[-client${ONEC_VERSION}]`, `client-toolbox:${ONEC_VERSION}`
- **OScript**: `oscript-jdk`, `oscript-jdk-s6`, `oscript-agent`
- **Agents**: `base-jenkins-agent:${ONEC_VERSION}`, `base-jenkins-coverage-agent:${ONEC_VERSION}`
- **Element Script**: `elementscript:${ELEMENTSCRIPT_VERSION}`
- In CI: platform in tag (`-k8s`/`-swarm`): `<version>-k8s`, `<version>-k8s-g<sha>`, `k8s` (floating)
- Use descriptive suffixes (`-nls`, `-vnc`, `-s6`)

### Volume Mounts

- Standard 1C paths: `/opt/1cv8/`, `/var/1cv8/`

### Network Configuration

- Standard 1C ports: 1540-1541 (server), 1545 (ras)
