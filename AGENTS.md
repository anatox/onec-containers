# GitHub Copilot Instructions for onec-containers

> **Phase 2 active**: `client`, `thin-client`, `crs`, `crs-apache`, `vanessa-runner`, `gitsync`, `executor` migrated to Pants. Pants version bumped to `2.33.0a0`. `rac-gui/` directory deleted (deprecated). Retired: `build-crs.sh`, `build-executor.sh`, `build-executor.yml`. Secrets file now `secrets.env` (id `secrets_env`) — includes `ONEC_USERNAME`, `ONEC_PASSWORD`, and `DEV1C_EXECUTOR_API_KEY`. Phase 1 server chain continues unchanged. Buildah + agent chains + git-tag releases still active for all phase-3 components (s6/vnc/jdk/test-utils/jenkins-agents/coverage/EDT/toolboxes).
> - **Secrets**: `secrets.env` (env-format, single `secrets_env` secret mount). `secrets.env.example` for reference.
> - **Local dev**: `.devcontainer/` recommended. `pants package server:onec-server-8.5.1.1343` builds the full chain.
> - **Image tags**: `<version>`, `<version>-g<sha>` (immutable), `latest` (last version only, main branch), `local` (no publish).
> - **Containerfile changes**: `oscript/Containerfile` LABEL moved after FROM (B1). `server/Containerfile` secrets consolidated to single `secrets_env` mount (B5). All migrated Containerfiles use `secrets_env` mount, repo-root-relative COPY paths.

## Project Overview

This repository contains container configurations for building images with 1C:Enterprise (1С:Предприятие) 8.3+ platform, a popular Russian ERP and business automation platform. The project provides containerized solutions for various 1C components including servers, clients, development tools, and CI/CD agents.

## Key Technologies and Patterns

### Core Technologies

- **Buildah**: Primary image build engine in scripts and CI actions
- **Compose**: Container orchestration for local integration scenarios
- **1C:Enterprise Platform 8**: Russian ERP platform
- **OneScript (oscript)**: Scripting language for 1C automation
- **EDT (Enterprise Development Tools)**: 1C development environment
- **Vanessa Runner**: Testing framework for 1C
- **Jenkins**: CI/CD integration with container agents

### Languages and Scripts

- **Containerfile**: Container definitions
- **Bash scripts**: Build automation and utilities
- **Makefile**: Build orchestration
- **Russian language**: Documentation, examples, comments and commit messages are primarily in Russian

## Repository Structure Guidelines

### Container Images Organization

Each directory represents a specific container image:

- `server/`: 1C:Enterprise server
- `client/`: 1C:Enterprise thick client
- `thin-client/`: 1C:Enterprise thin client
- `edt/`: Enterprise Development Tools
- `oscript/`: OneScript runtime
- `vanessa-runner/`: Testing framework
- `swarm-jenkins-agent/` and `k8s-jenkins-agent/`: CI/CD agents
- `coverage41C/`: Code coverage tools
- `client-toolbox/`: 1C:Enterprise client layer for Toolbox/Distrobox
- `edt-toolbox/`: EDT Toolbox image

### Build Scripts Pattern

- `build-*.sh`: Build scripts for local development
- Scripts follow naming pattern: `build-<component>-<environment>-<type>.sh`

## Coding Standards and Best Practices

### Containerfile Guidelines

1. **Multi-stage builds**: Use when downloading/building dependencies
2. **Secrets for credentials**: Use `RUN --mount=type=secret,id=onec_username --mount=type=secret,id=onec_password` and read from `/run/secrets/`:
   ```containerfile
   RUN --mount=type=secret,id=onec_username \
       --mount=type=secret,id=onec_password <<'EOF'
     set -eux
     /download.sh "$(cat /run/secrets/onec_username)" "$(cat /run/secrets/onec_password)" "$ONEC_VERSION" "server"
   EOF
   ```
3. **ARG variables**: Follow existing pattern for build arguments:
   ```containerfile
   ARG ONEC_VERSION
   ARG CONTAINER_REGISTRY_URL
   ```
4. **Base image pattern**: Prefer compound `ARG BASE_IMAGE=<name>:<tag>` (no separate `BASE_TAG`):
   ```containerfile
   ARG BASE_IMAGE=ubuntu:26.04
   FROM ${BASE_IMAGE}
   ```
   Or with registry substitution:
   ```containerfile
   FROM ${CONTAINER_REGISTRY_URL:+"$CONTAINER_REGISTRY_URL/"}base-image:tag
   ```
5. **Labels**: Include maintainer information
6. **Layer optimization**: Combine RUN commands to minimize layers

### Environment Variables

Standard environment variables used across the project:

- `ONEC_USERNAME`: 1C releases portal username
- `ONEC_PASSWORD`: 1C releases portal password
- `ONEC_VERSION`: 1C platform version (format: 8.x.x.xxxx)
- `EDT_VERSION`: EDT version
- `CONTAINER_REGISTRY_URL`: Container registry URL
- `COVERAGE41C_VERSION`: Coverage tool version
- `DEV1C_EXECUTOR_API_KEY`: API key for Executor downloads
- `EXECUTOR_VERSION`: 1C:Executor version

### Build Scripts

1. **Error handling**: Include proper error checking and exit codes
2. **Variable validation**: Check required environment variables
3. **Logging**: Provide informative output messages
4. **Cross-platform**: Shell scripts should work in Git Bash for Windows as well as POSIX-compatible platforms; use fallbacks or conditional logic for platform-specific features

### Makefile Targets

Follow existing pattern for Make targets:

- Use environment variables for configuration
- Include `buildah build` with proper arguments
- Tag images with both version and `latest` tags
- Use `.PHONY` declarations

## 1C:Enterprise Specific Guidelines

### Version Management

- 1C versions follow pattern: `8.3.x.xxxx` (e.g., 8.3.18.1520)
- Different components may require different version compatibility
- Check version compatibility when updating dependencies

### Localization Support

- Support both Russian and international localizations
- Use `NLS_ENABLED=true` build argument for multi-language support
- Preserve Russian language in comments and documentation

### Platform Components

- **Server**: Database server component
- **Client**: Full desktop client
- **Thin Client**: Web-based client
- **CRS**: Configuration Repository Server
- **RAC**: Remote Administration Console

## Security and Credentials

### Sensitive Information

- Never hardcode credentials in Containerfiles or scripts
- Use `--mount=type=secret` for credentials, never pass through ARG or ENV
- Pants components use a single `secrets_env` secret mount (the env file is sourced, so all vars are available)
- Buildah components in phase 3 still use two-mount `onec_username`/`onec_password` pattern
- Use build arguments for non-sensitive config (`ONEC_VERSION`, `CONTAINER_REGISTRY_URL`)
- Provide example files (`.example` suffix) for configuration
- Use environment variables for runtime configuration

### Download Authentication

- 1C platform requires authentication to download from releases.1c.ru
- Use oscript-library/yard tool for secure downloads when possible
- Handle download failures gracefully

## Architecture

- **Every image has a Containerfile in its own directory** and an optional `build-<component>.sh` for local dev builds. CI uses composite actions instead.
- **Build scripts vs CI**: `build-*.sh` scripts are for local development. CI workflows (`.github/workflows/build-*.yml`) use the composite actions but follow the same layer order. Never assume a build script exists for a CI-built image.
- **`scripts/installer/` is the `onec-install` toolchain**: `bin/onec-install` dispatches to `libexec/`. Other scripts in `scripts/` are copied into Containerfiles at build time.
- **Image naming convention**: `localhost/<name>:<tag>` for local, `ghcr.io/<owner>/<name>:<tag>` for published. Container names include `onec-<component>`, `executor`, `edt-toolbox`, `client-toolbox`, `gitsync`.
- **Toolbox images** use `quay.io/toolbx/ubuntu-toolbox:26.04` base instead of `ubuntu:26.04`. The toolbox label is already set by the base image; Containerfiles add distrobox shims for host-forwarding.

## Files That Must Change Together

- When adding a new component with CI: create `.github/workflows/build-<component>.yml`, update `README.md` table of contents and tag table, update `Layers.md`, add `vars.BUILD_<COMPONENT>` guard variable.
- When changing base Ubuntu version: `.github/actions/build-installer/action.yml` (`BASE_IMAGE` arg), all `build-*.sh` scripts, `.onec.env.example` (`TOOLBX_TAG`), `.envrc`, all Containerfiles with `ARG BASE_IMAGE`, workflow defaults.
- When changing `installer/Containerfile`: verify `scripts/installer/bin/onec-install` still supports component names used in build scripts (`client`, `server`, `crs`, `edt`).

## Image Layering

- Toolchain prerequisite for all 1C components: `oscript -> installer`. In CI this is `build-installer` composite action.
- Base agent chain: `oscript -> installer -> client -> s6-overlay -> client-vnc -> oscript -> jdk -> test-utils -> base-jenkins-agent`.
- Coverage agent builds on top of base-jenkins-agent plus EDT (for JAR extraction): `coverage41C/Containerfile` copies debug plugin JARs from a separately built EDT image.
- OScript agent uses `eclipse-temurin:17` base directly, no `oscript -> installer` prerequisite.
- `s6-overlay` is always a layer between app and agent, never the base or top.
- `client-toolbox/Containerfile` is reused as a generic "add 1C client to any base" layer by `build-edt-toolbox` workflow.
- Containers reference base images with single `BASE_IMAGE=<name>:<tag>` (no separate `BASE_TAG` arg).

## Non-Obvious Dependencies

- PostgreSQL image is not standard: `compose.yaml` uses `rsyuzyov/docker-postgresql-pro-1c`, a third-party image with 1C-compatible extensions.
- RAS reuses server image: `compose.yaml` runs `ras` service from `onec-server` image with entrypoint override to `/opt/1cv8/current/ras`.
- `gitsync` uses COPY --from phase-2 client for 1C platform and oscript base — no Debian Stretch repos.
- Manual-only images (no CI workflow): `oscript-utils` (deferred, needs refactor).

## Key Workarounds

- 1C ships its own `libstdc++` (`client-vnc/Containerfile`), which must be deleted before runtime or GUI can crash with GLIBCXX/GCC errors.
- EDT pre-2025 requires full JDK with JavaFX installed. 1C recommends BellSoft Liberica Full JDK. EDT <= 2023: Java 11, EDT 2024: Java 17, EDT >= 2025 bundles its own Axiom JDK.
- `iptables` must be held in s6-overlay and VNC images to prevent networking breakage.
- Xfce in containers requires `NO_AT_BRIDGE=1`, `QT_X11_NO_MITSHM=1`, and `xfce4-panel --disable-wm-check`.

## Build System

- `buildah`, not docker/buildx/podman build: CI uses `redhat-actions/buildah-build@v2` via `build-image` composite action. Build scripts use `buildah build`.
- `build-image` action (`.github/actions/build-image/action.yml`) handles metadata, build, push-to-GHCR, and cosign sign in one step. `publish` must be `'true'` (string) for push and sign.
- `build-installer` action builds `oscript` then `onec-installer`. Every component that downloads 1C bits depends on it.
- `build-edt` action depends on `build-installer`: builds `oscript -> installer -> edt`.
- Cache mount `distr-cache` (`/var/cache/yard`) is shared across all Containerfiles for downloaded 1C distributions.
- Local `distr/` directory is copied into installer stage for offline builds; `yard-download.sh` auto-detects matching archives.

### Pants (Phase 2 — server chain + client family)

- `build_file_prelude_globs = ["versions/*.py", "build_support/*.py"]` injects those files' variables directly into every BUILD file scope — no imports needed.
- `pants.ci.toml` activates `use_buildx = true` and configures `[docker.registries.ghcr]` for GHCR push. CI sets `PANTS_CONFIG_FILES=pants.ci.toml`.
- `PLATFORM_VERSIONS` is a tuple, not a list. Use `max()` for latest-version logic, not `[-1]` — Pants' BUILD evaluator doesn't reliably support negative tuple indexing.
- Pants `docker_image` resolves inter-image dependencies via target names (e.g. `oscript:oscript`), not localhost tags. Containerfile `FROM` ARGs use target-named references like `ARG BASE_IMAGE=oscript:oscript`.
- Secrets under Pants: BUILD files declare `secrets={"secrets_env": secrets_file("secrets.env")}`. Containerfiles read a single file secret via `--mount=type=secret,id=secrets_env` and source it: `set -a; . /run/secrets/secrets_env >/dev/null 2>&1; set +a`. The `secrets_file()` helper is a pass-through identity function — a semantic marker required by Pants API.
- `cache_args()` returns `cache_to`/`cache_from` dicts for registry-backed layer caching (`mode: "max"` for all layers). Only active when `PANTS_DOCKER_CACHE_PREFIX` env var is set.
- `server/BUILD` uses `context_root="."` so the build context is the repo root. All Containerfile COPY paths are repo-root-relative (e.g. `COPY server/entrypoint.sh /...`, not `COPY ./server/entrypoint.sh /...`). Without this, Pants defaults to per-directory context and cross-directory COPYs fail.
- **No redundant `extra_build_args`**: never pass a build arg whose value equals the Containerfile ARG default. Image-ref FROM-args (e.g. `ARG BASE_IMAGE=ubuntu:26.04`) live as Containerfile defaults; `extra_build_args` only for values that genuinely vary (versions from `versions/*.py`, per-version target addresses like `BASE_IMAGE=crs:onec-crs-8.5.1.1343`).
- **Duplicate ARG constraint**: Pants' parser (`duplicates_must_match=True`) rejects Containerfiles that redeclare the same ARG name with different defaults. Use distinct ARG names for distinct purposes (e.g. `CLIENT_IMAGE` + `OSCRIPT_IMAGE` in gitsync instead of dual `BASE_IMAGE`).
- **Pants 2.32 FROM-arg bug (pantsbuild/pants#23425), FIXED in 2.33.0a0**: on Pants < 2.33, a Containerfile must not mix target-address FROM-args (`ARG INSTALLER_IMAGE=installer:onec-installer`) with plain registry-ref FROM-args (`ARG BASE_IMAGE=ubuntu:26.04`). Fixed upstream, merged into `main` 2026-07-07, first released in **2.33.0a0**. With the bump to 2.33.0a0, mixed FROM-args are safe again. Track: bump to 2.33.0 stable when released.
- **build-image action `file_secrets`**: optional `file_secrets` input (newline-separated `id=path`) emits `--secret=id=<id>,src=<path>` for buildah builds. Used by phase-3 agent chains that need to pass `secrets.env` as a file secret.

## Git Tag-Based CI

> **⚠️ Устарело (Phase 1 Pants)**: Система сборки через git-теги (`packages/<component>/v<version>`) **выведена из эксплуатации** для `oscript`, `installer` и `server`. Push таких тегов больше не запускает сборку — используйте `workflow_dispatch` в `release.yml` или push в `main`. Компоненты фазы 2+ продолжают использовать Buildah + git-теги.

- Tag format: `packages/<component>/v<version>[-r<N>]`
- `resolve-tag` action: plain tags (`v8.5.1.1343`) auto-increment to immutable `-rN` tags. Tags already with `-rN` pass through unchanged.
- Resolved `-rN` tag is pushed and plain tag deleted from origin in one atomic push (`git push origin refs/tags/A :refs/tags/B`). Race conditions cause build failure.
- Compound tags with dependency suffixes: `packages/edt-toolbox/v2025.2.6-client8.5.1.1343` -> `version_main` + `version_deps=["client8.5.1.1343"]`.
- `edt-toolbox` builds two images from one tag: `edt-toolbox:VER-base-rN` (EDT only) then `edt-toolbox:VER-clientONECVER-rN` using `client-toolbox/Containerfile`.
- After local push, plain tags remain in local clone; clean with `git fetch --prune --tags origin`.
- `fetch-depth: 0` required for tag-triggered builds, `fetch-depth: 1` for PR.
- PR guard variables: `vars.BUILD_SERVER != 'false'`, etc. If not set at all, build runs.

## CI / act (Local Testing)

- Runner image: `catthehacker/ubuntu:act-latest`.
- `--concurrent-jobs 1` required for `act < 0.2.89`.
- Use `workflow_dispatch` event for local-only builds (no publish). `push` event triggers publish.
- `--container-architecture linux/amd64` required; build images are x86_64 only.
- All CI secrets go to `--secret=id=X,type=env` via `build-image` action. Never through ARG/ENV.

## Documentation Standards

### Code Comments

- Use Russian for 1C-specific terminology
- Include English translations for common international concepts
- Document version compatibility and requirements

### README.md and AGENTS.md Updates

- Update version information when adding new components
- Include build examples for new container images
- Maintain table of contents structure

## Common Patterns to Follow

### Container Naming

- **Platform images**: `onec-<component>:${VERSION}` (e.g., `onec-server:8.5.1.1343`), `onec-client:${VERSION}`
- **EDT images**: `edt:${EDT_VERSION}` (e.g., `edt:2025.2.6`), `edt-s6:${EDT_VERSION}`, `edt-agent:${EDT_VERSION}`
- **Toolbox images**: `edt-toolbox:${EDT_VERSION}[-client${ONEC_VERSION}]` (e.g., `edt-toolbox:2025.2.6-client8.5.1.1343-r1`), `client-toolbox:${ONEC_VERSION}`
- **OScript images**: `oscript-jdk`, `oscript-jdk-s6`, `oscript-agent` (versioned by OneScript version)
- **Agent images**: `base-jenkins-agent:${ONEC_VERSION}`, `base-jenkins-coverage-agent:${ONEC_VERSION}`
- **Executor**: `executor:${EXECUTOR_VERSION}`
- In CI, tags follow the `-r<N>` scheme (see Git Tag-Based CI) for non-Pants components. Pants components use `<version>-g<sha>`.
- Use descriptive suffixes (`-nls`, `-vnc`, `-s6`, etc.)
- Tag both specific component version and `latest` for latest main branch build

### Volume Mounts

- Follow 1C standard paths: `/opt/1cv8/`, `/var/1cv8/`

### Network Configuration

- Use standard 1C ports (1540-1541 for server, 1545 for ras)
