# 1C:Enterprise container images

## Project Overview

This repository contains Docker configurations for building Docker images with 1C:Enterprise (1С:Предприятие) 8.3+ platform - a popular Russian ERP and business automation platform. The project provides containerized solutions for various 1C components including servers, clients, development tools, and CI/CD agents.

## Key Technologies and Patterns

### Core Technologies
- **Docker & Docker Compose**: containerization and orchestration
- **Buildx Bake**: Build orchestration
- **Bakery/Bake CLI**: Custom `buildx bake` wrapper with autodiscovery and dependency management
- **1C:Enterprise Platform**: Russian ERP platform (versions 8.3+)
- **OneScript (oscript)**: Scripting language for 1C automation
- **EDT (Enterprise Development Tools)**: 1C development environment
- **Vanessa Runner**: Testing framework for 1C
- **Element Script**: 1C:Enterprise Element.Script runtime
- **Jenkins**: CI/CD integration with Docker agents

### Languages and Scripts
- **Dockerfile**: Container definitions
- **HCL**: configuration files for buildx bake
- **Python**: Main language for `bakery` cli
- **Russian language**: Documentation and comments are primarily in Russian
- **AGENTS.md** files are in English

## Repository Structure Guidelines

### Docker Images Organization
Each directory represents a specific Docker image:
- `server/`: 1C:Enterprise server
- `client/`: 1C:Enterprise thick client
- `thin-client/`: 1C:Enterprise thin client
- `edt/`: Enterprise Development Tools
- `oscript/`: OneScript runtime
- `vanessa-runner/`: Testing framework
- `swarm-jenkins-agent/` and `k8s-jenkins-agent/`: CI/CD agents
- `coverage41C/`: Code coverage tools
- `s6-overlay/`: s6 overlay
- `jdk/`: OpenJDK overlay
- `test-utils/`: Vanessa-automation overlay
- `client-vnc/`: VNC-enabled client image
- `installer/`: builds and publishes the reusable `onec-install` toolchain image from `scripts/installer/` (`bin/onec-install` → `libexec/`); consumed via `INSTALLER_IMAGE`

## Coding Standards and Best Practices

### Dockerfile Guidelines
1. **Multi-stage builds**: Use when downloading/building dependencies
2. **Secrets**: `RUN --mount=type=secret,id=onec_username` / `id=onec_password`, mapped from env in bake.hcl `secret` block
3. **ARG variables**: Follow existing pattern for build arguments:
   ```dockerfile
   ARG ONEC_VERSION
   ARG BASE_IMAGE=<name>:<tag>
   FROM ${BASE_IMAGE}
   ```
4. **Labels**: Include maintainer information
5. **Layer optimization**:
   - Combine RUN commands to minimize layers
   - Order matters for cache reuse: install deps in a layer that only re-runs when their manifest changes, then `COPY` source later
   - Use BuildKit's `COPY --chmod=<mode> --chown=<user:group>` shorthand instead of separate `COPY` + `RUN chmod/chown`
   - Use `RUN --mount=type=cache,target=/var/cache/apt,sharing=locked` (and `/var/lib/apt/lists`) for apt to keep package downloads between builds — but the persisted `lock` files break `apt-get update`, so delete them first: `find /var/lib/apt/lists -name lock -delete`
   - **Reuse the installer stage** for vendor binaries: declare `ARG INSTALLER_IMAGE=localhost/onec-installer:local` and `FROM ${INSTALLER_IMAGE} AS installer`, then `COPY --from=installer` only the specific platform paths you need (e.g. `/opt/1cv8`, `/opt/1C/1CE`).


### Environment Variables
Standard environment variables used across the project:
- `ONEC_USERNAME`: 1C releases portal username
- `ONEC_PASSWORD`: 1C releases portal password
- `ONEC_VERSION`: 1C platform version (format: 8.x.x.xxxx)
- `EDT_VERSION`: EDT version
- `DOCKER_REGISTRY_URL`: Docker registry URL
- `ELEMENTSCRIPT_DOWNLOAD_KEY`, `ELEMENTSCRIPT_VERSION`: 1C:Enterprise Element.Script

### Build Scripts
1. **Error handling**: Include proper error checking and exit codes
2. **Variable validation**: Check required environment variables
3. **Logging**: Provide informative output messages
4. **Cross-platform**: Maintain cross-platform compatibility for host scripts

## 1C:Enterprise Specific Guidelines

### Version Management
- 1C versions follow pattern: `8.3.x.xxxx` (e.g., 8.3.18.1520)
- Different components may require different version compatibility
- Check version compatibility when updating dependencies

### Localization Support
- Support both Russian and international localizations
- Use `NLS_ENABLED=1` build argument for multi-language support
- Preserve Russian language in comments and documentation

### Platform Components
- **Server**: Database server component
- **Client**: Full desktop client
- **Thin Client**: Web-based client
- **CRS**: Configuration Repository Server
- **RAC**: Remote Administration Console

## Build System

`docker buildx bake` with custom HCL configuration. Targets in `*/bake.hcl` alongside Dockerfiles, shared variables/functions/groups in `bakery/`. Inter-image dependencies via named contexts. Selector (`bakery/select.py`) computes affected-closure from git diff and context graph. CLI subcommands via invoke: `./bake build`, `./bake plan`, `./bake select`, `./bake lint`.

- Every image has a Dockerfile in its own directory and a `bake.hcl` with a target block


### Bakery CLI
- `./bake build default`: build all targets in the default group; comma-separate for several targets/groups at once (`./bake build client,server`)
- `./bake plan` / `./bake select --git-range <range>`: plan and affected-only selection

Full reference and implementation details: `@bakery/AGENTS.md`.

#### HCL File Layout
- `bakery/versions.hcl` - version pins only
- `bakery/common.hcl` - infrastructure/build variables + functions
- `bakery/groups.hcl` - default/publish groups
- `*/bake.hcl` in every directory with a Dockerfile

#### Named Context Rule
The context key must **exactly match** the ARG default in the Dockerfile:

- **Base-image targets** (oscript, elementscript, and the BASE_IMAGE lines of client/server/edt/thin-client/crs) default to a public image such as `ubuntu:26.04` — no named context or `args` override is needed:

```hcl
# Dockerfile: ARG BASE_IMAGE=ubuntu:26.04
# bake.hcl: no contexts block, no args override
```

- **Dependency-override targets** (installer, gitsync, vanessa-runner, coverage41C, crs-apache, and the INSTALLER_IMAGE lines) default to `localhost/<dep>:local` — a matching named context resolves to the dependency build target:

```hcl
# Dockerfile has ARG INSTALLER_IMAGE=localhost/onec-installer:local
contexts = {"localhost/onec-installer:local" = "target:installer"}
```

- **Overlays/consumers** (s6-overlay, jdk, test-utils, agents) use bare `ARG BASE_IMAGE` (no default) — the consumer target supplies both `args` and `contexts`:

```hcl
args     = {BASE_IMAGE = "localhost/onec-client:local"}
contexts = {"localhost/onec-client:local" = "target:client"}
```
Resolution: context key matches against any tag of the target (not just a specific one).

#### Multi-stage Dockerfile for variant targets
A single Dockerfile can serve multiple bake targets via named stages:
```hcl
target "client"           { target = "client" }
target "client-toolbox"   { target = "toolbox", args = { BASE_IMAGE = "quay.io/…" } }
target "edt-toolbox"      { target = "toolbox" }
target "edt-toolbox-client" { dockerfile = "client/Dockerfile", target = "base" }
```
Overlay targets (s6-overlay, jdk, test-utils) are defined at the consumer, not in the snippet directory.

#### Tag Scheme
- Local: `localhost/<image>:local`, `localhost/<image>:<version>`, `localhost/<image>:<short>` (short = `shortver(version)`)
- CI (REGISTRY_PREFIX + GIT_SHA): additionally `<prefix>/<image>:<version>`, `<prefix>/<image>:<short>`, `<prefix>/<image>:<version>-g<sha7>`
- CI + PUBLISH_LATEST (regular images): also `<prefix>/<image>:latest`. The `latest` tag is conditional on `PUBLISH_LATEST=true` and is only emitted from the `tags()`/`tags_suffixed()` helpers in `bakery/common.hcl`; it is never produced locally.
- **Agents** — platform-agnostic repo name (`onec-jenkins-agent`, `edt-agent`, `oscript-jenkins-agent`), platform in tag:
  - `localhost/<agent>:local-<k8s|swarm>`, `:<version>-<k8s|swarm>`, `:<short>-<k8s|swarm>`
  - Floating (replaces latest): `:<k8s|swarm>`. Agents do not emit a `latest` tag; the platform-specific floating tag (`k8s` / `swarm`) is the single mutable pointer to the most recent build for that platform and is independent of `PUBLISH_LATEST`.

#### Labels & Selector Metadata
- **HCL labels**: `org.opencontainers.image.title` and `org.opencontainers.image.version` must be declared in each target's `labels` map.
- **Generated labels**: `org.opencontainers.image.description`, `org.opencontainers.image.vendor`, and all other `org.opencontainers.image.*` keys come from `docker/metadata-action` in CI via `inherits`.
- **Description JSON keys**: `"image"` (registry repo name, mandatory) and optional `"extra-srcs"` (list of paths the target reads from outside its own directory — e.g. `scripts/`, another component's `configs/`). The selector uses `extra-srcs` to map those source paths back to the targets that own them, so editing them rebuilds consumers too. Stored via `description = jsonencode({"image" = "...", ...})` — never lands on the built image.
- Intermediate targets not intended for publishing are simply omitted from `group "publish"` in `bakery/groups.hcl`.

#### Adding a new target — checklist
1. Dockerfile in its own directory, `ARG BASE_IMAGE=localhost/<dep>:local` (or `ARG INSTALLER_IMAGE=...`)
2. `*/bake.hcl`: target block with `dockerfile`, `contexts`, `args`, `tags`, `labels`, `cache_from`, `cache_to`
3. `description = jsonencode({"image" = "<registry-repo-name>"})` (merge in `"extra-srcs"` for all cross-dir COPY from scripts/, other directories)
4. `bakery/groups.hcl`: add to `group "default"`; to `group "publish"` if not skip-publish
5. `tests/test_bake_select.py` — re-run `python3 -m unittest tests/test_bake_select.py` (add a test case if new edge topology)
6. Verify: `./bake plan | ./bake select --changed <new>/Dockerfile` → non-empty build-set

#### Compose
- `docker-compose.yml`: developer runtime stack (srv/db/repo/ras/client)
- `tests/compose.yaml`: registry:2 helper for E2E testing of publish/cache

## Security and Credentials

### Sensitive Information
- Never hardcode credentials in Dockerfiles or scripts
- Use `--mount=type=secret` for credentials (`ONEC_USERNAME`, `ONEC_PASSWORD`)
- Provide example files (.example suffix) for configuration
- Use environment variables for runtime configuration

### Download Authentication
- 1C platform requires authentication to download from releases.1c.ru
- Use YARD tool for secure downloads when possible
- Use SHA256 checksums to verify direct URL downloads when available (dynamically)
- Handle download failures gracefully

## Testing and Validation

### Build Validation
- Test builds with different 1C versions
- Validate multi-architecture support where applicable
- Respect validation rules defined in .pre-commit-config.yaml and .github/workflows/pre-build.yml

### Integration Testing
- Test with docker-compose configurations
- Validate Jenkins agent functionality
- Check VNC connectivity for GUI clients
- Check distrobox connectivity for toolbox images.

## Documentation Standards

### Code Comments
- Use Russian for 1C-specific terminology
- Include English translations for complex concepts
- Document version compatibility and requirements
- When rewriting source files, preserve existing comments.

### README Updates
- Update version information when adding new components
- Include build examples for new Docker images
- Maintain table of contents structure

## Common Patterns to Follow

### Container Naming
`localhost/<name>:<tag>` locally, `<env.REGISTRY>/<name>:<tag>` in CI

- **Platform images**: `onec-<component>:${VERSION}`, `onec-client:${VERSION}`
- **EDT**: `edt:${EDT_VERSION}`, `edt-s6:${EDT_VERSION}`, `edt-agent:${EDT_VERSION}`
- **OScript**: `oscript-jdk`, `oscript-jdk-s6`, `oscript-jenkins-agent`
- **Element Script**: `onec-elementscript:${ELEMENTSCRIPT_VERSION}`
- **Agents**: `onec-jenkins-agent:${ONEC_VERSION}-k8s`, `onec-coverage-jenkins-agent:${COVERAGE41C_VERSION}-swarm`
- Container platform in tag (`-k8s`/`-swarm`): `<version>-k8s`, `<version>-k8s-g<sha>`, `k8s` (floating)
- Use descriptive suffixes (`-nls`, `-vnc`, `-s6`)
- Tag both specific version and 'latest'
- **Toolbox image flavors**: `edt-toolbox:${EDT_VERSION}[-client${ONEC_VERSION}]`, `onec-client-toolbox:${ONEC_VERSION}`, BASE_IMAGE: `quay.io/toolbx/ubuntu-toolbox:26.04` base instead of `ubuntu:26.04`, distrobox shims for host-forwarding

### Volume Mounts
- Follow 1C standard paths: `/opt/1cv8/`, `/var/1cv8/`
- Use consistent mount points across related containers
- Document required volumes in README

### Network Configuration
- Use standard 1C ports (1540-1541 for server, 1545 for ras)
- Document port requirements for each service
- Consider cluster configurations

## Maintenance Guidelines

### Version Updates
- Update .env.example files when changing default versions
- Test compatibility across the entire stack
- Update documentation with version-specific changes

### Dependencies
- Monitor 1C platform releases for security updates
- Keep OneScript and related tools updated
- Declare versioned dependencies/components in versions.hcl
- Validate third-party tool compatibility

## Error Handling

### Common Issues
- Authentication failures to 1C releases portal
- Download failures due to network issues
- Version compatibility problems
- Network connectivity issues during builds
- Missing dependencies or tools
- GLIBCXX/Java module errors at runtime: 1C ships its own std libs which can shadow the OS packages — `rm` the vendored copy and reinstall the OS package (see Key Workarounds above)

### Debug Information
- Include version information in build outputs
- Log download URLs and file checksums
- Preserve error messages in Russian when from 1C tools

## Code Review

Reviews must focus exclusively on the changes introduced in the pull request. Pre-existing code, style, or behaviour outside the diff is out of scope and should not be raised as blocking feedback. The only exception is when a change in the PR causes a regression in code that was not itself modified — in that case, call it out explicitly and tie the report back to the change that triggered it.

## AI Assistant Guidelines

When working with this repository:

1. **Respect the bilingual nature**: Maintain Russian language in documentation and comments for 1C-specific terminology while providing English explanations for international contributors
2. **Follow 1C conventions**: Understand that 1C:Enterprise has specific naming conventions, file structures, and deployment patterns
3. **Consider enterprise context**: This is enterprise software with licensing, authentication, and complex deployment requirements
4. **Maintain security**: Always use build secrets (`--mount=type=secret,id=...`) for credentials, never use build arguments or hardcode sensitive information
5. **Test comprehensively**: Changes should be tested across multiple 1C versions and deployment scenarios
6. **Document thoroughly**: Include both Russian and English documentation for new features

Remember: This project serves the Russian 1C community, so maintain Russian language support and cultural context while ensuring international accessibility through clear documentation and examples.
