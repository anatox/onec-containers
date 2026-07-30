# bakery/ — Build system internals

For HCL layout, named contexts, tag scheme, labels, and the new-target checklist, see the root `@AGENTS.md`.

## HCL loading

- `bakery/buildx.py::discover_hcl_files` collects `bakery/*.hcl` + `*/bake.hcl` and passes each as an explicit `-f` flag. Buildx auto-discovery only finds `docker-bake.hcl`/`docker-bake.override.hcl` at the project root and would otherwise miss everything under `bakery/` and `*/bake.hcl`.
- All HCL files are merged before evaluation — variables and user functions from one file are visible in others.
- `./bake plan` runs `docker buildx bake --print` and writes the resulting JSON to stdout; progress logs go to stderr.

## HCL: buildx bake runtime capabilities and limits

- `split`/`slice`/`length`/`join` and `for`-expressions (`[for p in parts : f(p)]`) are reliable for string work.
- `regex_replace` escaping is unreliable in bake — avoid; rewrite with `split`/`slice`/`join`.
- User functions can call other user functions but **cannot** be referenced from `variable` blocks (only stdlib and other `variable`s can).
- No function overloading or optional parameters — provide separate variants (`tags`, `tags_full`).
- No runtime type introspection (`is_list`, etc.).

## Architecture

`./bake` is a bash wrapper that bootstraps a project-local `.venv` (re-keyed on `pyproject.toml` sha256) and `exec`s the installed `bake` console-script, which runs `python3 -m bakery.main` (an invoke `Program`).

| Module | Role |
|---|---|
| `bakery/main.py` | invoke `Program` exposing tasks: `build`, `plan`, `select`, `lint` |
| `bakery/buildx.py` | HCL discovery, `docker buildx bake` argv assembly (`buildx_args`), GHA workflow-command re-emission, execution |
| `bakery/plan.py` | `plan_json()` runs `bake --print`; `obtain_plan()` prefers piped JSON from stdin |
| `bakery/select.py` | stdlib-only affected-closure: `gh_output`, `matrix_json`, `select`, `resolve_git_range` |
| `bakery/versions.hcl` | Pinned 1C component versions |
| `bakery/common.hcl` | Shared build vars and helper functions |
| `bakery/groups.hcl` | `group "default"` and `group "publish"` target sets |

## Selector (`bakery/select.py`)

Computes the build matrix for CI from the bake JSON plan + a list of changed paths. Pipeline:

```bash
./bake plan > bake-plan.json
./bake select --git-range HEAD~1..HEAD --github-output < bake-plan.json
```

Algorithm:
1. `dirname(dockerfile)` → directory → target seeds.
2. `description.extra-srcs` → extra path prefixes → target seeds.
3. Reverse-dependency graph from `contexts` values matching `target:<dep>`.
4. Transitive closure of dependents → `build` set.
5. `build` ∩ `group "publish"` → `publish` matrix (image from `description.image`, title/version from `labels`).
6. Any path in `GLOBAL_BUILD_ALL` (`bakery/`, `pyproject.toml`, `bake`, `.dockerignore`, `.github/`) forces `all=True`.

An unresolvable `--git-range` (e.g. first push of a branch) falls back to `--all` with a stderr warning.

## CI

`.github/workflows/build.yml`:
- `push` / `pull_request`: plan job checks out depth 0, runs `./bake plan` and `./bake select --git-range <before>..<after>`, emits a GHA matrix.
- `workflow_dispatch`: `--all` (or `--pattern`).
- Required secrets passed to `./bake build` via env: `ONEC_USERNAME`, `ONEC_PASSWORD`, `ELEMENTSCRIPT_DOWNLOAD_KEY`.

## invoke task constraints

- **`iterable=[...]` args can never be positional** — even a bare word (`bake build oscript`) will not be routed into a list arg. Use `str` positionals and split on `,` inside the task body (`./bake build default,publish`).
- **`invoke.program.Program` rejects extra positional args** — CLI subcommands must match defined tasks exactly; pass everything else via `--` (forwarded as `extra`).
- `buildx.bake(targets: list[str])` accepts a list; `buildx_args(target=...)` is single-target only and is used by `plan_json`.
