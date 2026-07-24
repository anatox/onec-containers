# bakery/ — Build system internals: HCL discovery, buildx wrapper, plan, selector, CLI

For HCL layout, named contexts, tag scheme, labels, and the new-target checklist, see the root `AGENTS.md`.

## Architecture

`./bake` and `./bake-select` are bash wrappers that bootstrap a `.venv` and delegate:
- `./bake` → `python3 -m bakery.main` (invoke CLI)
- `./bake-select` → `python3 -m bakery.select` (standalone selector)

Python modules:

| File | Role |
|---|---|
| `bakery/main.py` | invoke `Program` with tasks: `build`, `plan`, `select`, `lint` |
| `bakery/buildx.py` | HCL file discovery, `docker buildx bake` command assembly, execution |
| `bakery/plan.py` | `plan_json()` — runs `docker buildx bake --print`, captures JSON |
| `bakery/select.py` | Affected-closure from git diff + context graph, `gh_output`, `matrix_json` |
| `bakery/versions.hcl` | Version pins for 1C components |
| `bakery/common.hcl` | Shared build variables, helper functions |
| `bakery/groups.hcl` | `group "default"` and `group "publish"` target sets |

## Selector

`bakery/select.py` — stdlib-only Python, computes affected-closure:

```bash
./bake plan > bake-plan.json
./bake select --git-range HEAD~1..HEAD --github-output < bake-plan.json
```

Logic:
1. `dirname(dockerfile)` → directory-to-targets mapping
2. `description.extra-srcs` (JSON) → path-prefix-to-targets mapping
3. Reverse graph from `contexts` values of `target:<dep>`
4. Changed files → seeds → transitive closure of dependents
5. Global build-all paths: `bakery/`, `pyproject.toml`, `bake`, `.dockerignore`, `.github/`
6. Publish partition: build set ∩ `group "publish"` targets; image name from `description.image`, title/version from labels

## CI

`.github/workflows/build.yml`:
- `push`: plan job (checkout depth 0 → `--git-range`) → build matrix per published target
- `pull_request`: plan job (checkout depth 0 → `--git-range`) → build matrix per published target
- `workflow_dispatch`: `--all` (or `--pattern`)
- Secrets: `ONEC_USERNAME`, `ONEC_PASSWORD`, `ELEMENTSCRIPT_DOWNLOAD_KEY`

## Limitations

- `git mv olddir newdir` when `newdir` already exists pushes olddir INTO newdir (`newdir/olddir/`). Rename via a temp name: `git mv olddir .olddir.tmp` then `git mv .olddir.tmp newdir`.

## invoke task constraints

- `iterable=[...]` args can **never** be positional, even bare-word (`bake build oscript` without `--target`) — `invoke/parser/argument.py::Argument.__init__` hard-codes `kind is list` args to start with `_value = []` (not `None`), so `Context.missing_positional_args` (which filters on `value is None`) never sees them as unfilled and the parser never routes a bare token into them; it falls through to "no idea what '<token>' is". Confirmed by tracing `INVOKE_DEBUG=1`. Symptom bit `bake build oscript` in `main.py` until fixed. Invoke also has no `nargs='+'`-style variadic positional: `see_positional_arg` fills exactly one still-`None` positional slot per token, `break`s — so a single positional can never bare-word-collect more than one token either. `build`'s `target` is therefore a required `str` positional, and multi-target is handled by splitting on `,` *inside* the task body (`bake build default,publish`), not by any invoke-level list mechanism.
- `invoke.program.Program` rejects extra positional args: CLI subcommands must match defined tasks exactly.
- `buildx.bake(targets: list[str])` accepts list of targets; `buildx_args(target: str)` is single-target only (used by `plan_json`).

## mypy: extensionless script collisions

- Extensionless scripts map to `__main__`, not to their filenames — mypy cannot disambiguate two scripts in the same directory because both resolve to `__main__`. Check them in separate invocations or alongside the package: `mypy --strict script1 pkg/` + `mypy --strict script2`.
- `--scripts-are-modules` reverses this: scripts become modules named after their files, which can conflict with same-named packages (`Duplicate module named "pkg"`). At the repo root, where scripts and package directories coexist, this re-creates the problem that dropping `.py` extensions was meant to solve.
