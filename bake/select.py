#!/usr/bin/env python3
"""Change-to-matrix selector for buildx bake.

Reads a bake --print JSON plan (with default and publish groups),
computes which targets need to rebuild from changed file paths,
and emits GitHub Actions matrix output.

Selection logic:
  1. dirname(dockerfile) → target(s) for each changed file
  2. description "extra-srcs" → target(s) for cross-dir COPY inputs
  3. Reverse dependency graph from contexts values of form "target:<name>"
  4. Transitive dependents closure → affected build set
  5. Publish matrix = build set ∩ publish group targets
  6. Global build-all paths: bake/, bake/cli.py, .dockerignore,
     bake/select.py, .github/

Usage:
  ./bake.py --print | python3 -m bake.select --plan - --changed server/Dockerfile
  ./bake.py --print | python3 -m bake.select --plan - --git-range HEAD~1..HEAD
  ./bake.py --print | python3 -m bake.select --plan - --all
  ./bake.py --print | python3 -m bake.select --plan - --all --pattern 'server*'

The bake plan must include the publish group:
  ./bake.py --print default publish > bake-plan.json

Unit tests: python3 -m unittest tests/test_select.py
"""

import argparse
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Any, Optional

GLOBAL_BUILD_ALL = {
    "bake/",
    "bake/cli.py",
    ".dockerignore",
    "bake/select.py",
    ".github/",
}


def load_plan(path: str) -> Any:
    if path == "-":
        return json.load(sys.stdin)
    with open(path) as f:
        return json.load(f)


def build_dir_map(targets: dict[str, Any]) -> dict[str, list[str]]:
    dir_map: defaultdict[str, list[str]] = defaultdict(list)
    for name, data in targets.items():
        dockerfile = data.get("dockerfile", "")
        if dockerfile:
            d = os.path.dirname(dockerfile)
            if d:
                dir_map[d].append(name)
    return dict(dir_map)


def build_reverse_graph(targets: dict[str, Any]) -> dict[str, list[str]]:
    rev: defaultdict[str, set[str]] = defaultdict(set)
    for name, data in targets.items():
        contexts = data.get("contexts", {})
        for ctx_val in contexts.values():
            if isinstance(ctx_val, str) and ctx_val.startswith("target:"):
                dep = ctx_val[len("target:") :]
                rev[dep].add(name)
    return {k: sorted(v) for k, v in rev.items()}


@dataclass
class Description:
    """Normalized selector-only metadata carried in a target's description."""

    image: str
    extra_srcs: list[str] = field(default_factory=list)


def parse_description(data: dict[str, Any]) -> Optional[Description]:
    """Parse a target's JSON description field into a Description.

    Returns a Description(image=..., extra_srcs=[...]) on success, or None
    when the description is missing, not valid JSON, not an object, or has
    no "image" key — a description without "image" is treated as unset
    entirely, since every real target must carry it. Used to carry
    selector-only metadata (image name, extra-srcs) that must not become an
    actual image label.
    """
    desc = data.get("description", "")
    if not desc:
        return None
    try:
        obj = json.loads(desc)
    except (json.JSONDecodeError, TypeError):
        return None
    if not isinstance(obj, dict) or "image" not in obj:
        return None
    srcs = obj.get("extra-srcs", [])
    if isinstance(srcs, str):
        srcs = [srcs]
    elif not isinstance(srcs, list):
        srcs = []
    return Description(
        image=obj["image"],
        extra_srcs=[s.strip() for s in srcs if isinstance(s, str) and s.strip()],
    )


def build_extras_map(targets: dict[str, Any]) -> dict[str, list[str]]:
    """Map path prefix → target names from JSON description field.

    Reads target.description as JSON, extracts the "extra-srcs" list.
    Silently skips targets without descriptions or with non-JSON descriptions.
    """
    extras_map: defaultdict[str, set[str]] = defaultdict(set)
    for name, data in targets.items():
        desc = parse_description(data)
        if not desc:
            continue
        for prefix in desc.extra_srcs:
            extras_map[prefix].add(name)
    return {k: sorted(v) for k, v in extras_map.items()}


def changed_files_to_targets(
    changed: list[str],
    dir_map: dict[str, list[str]],
    extras_map: dict[str, list[str]],
) -> set[str]:
    """Map a set of changed file paths to initial affected targets."""
    targets: set[str] = set()
    for path in changed:
        path = path.strip()
        if not path:
            continue
        parts = path.split("/")
        for depth in range(len(parts)):
            prefix = "/".join(parts[: depth + 1])
            if not prefix:
                continue
            if prefix in dir_map:
                targets.update(dir_map[prefix])
            if prefix in extras_map:
                targets.update(extras_map[prefix])
        for ep in extras_map:
            if path.startswith(ep.rstrip("/") + "/") or path == ep:
                targets.update(extras_map[ep])
    return targets


def transitive_dependents(seeds: set[str], rev_graph: dict[str, list[str]]) -> list[str]:
    closure = set(seeds)
    queue = list(seeds)
    while queue:
        node = queue.pop()
        for dep in rev_graph.get(node, []):
            if dep not in closure:
                closure.add(dep)
                queue.append(dep)
    return sorted(closure)


def is_build_all_path(path: str) -> bool:
    for prefix in GLOBAL_BUILD_ALL:
        if path == prefix.rstrip("/") or path.startswith(prefix):
            return True
    return False


def partition_publish(
    targets: dict[str, Any],
    build_set: list[str],
    publish_set: set[str],
) -> list[dict[str, str]]:
    """Filter build set to publish-group members.

    Returns list of {"target", "image", "title", "version", "name"} dicts for
    GHA matrix. Image comes from the description JSON's "image" key
    (selector-only metadata, not an actual image label), title from the
    org.opencontainers.image.title label, version from the
    org.opencontainers.image.version label (title/version always present on
    every publish target). Publish-group targets missing title or version are
    a configuration error since docker/metadata-action needs them at build
    time.
    """
    publish = []
    for t in build_set:
        if t in publish_set:
            labels = targets[t].get("labels", {})
            title = labels.get("org.opencontainers.image.title", "")
            version = labels.get("org.opencontainers.image.version", "")
            if not title or not version:
                print(
                    f"ERROR: {t} is in publish group but missing image.title or image.version label",
                    file=sys.stderr,
                )
                sys.exit(1)
            desc = parse_description(targets[t])
            image = desc.image if desc else t
            publish.append(
                {
                    "target": t,
                    "image": image,
                    "title": title,
                    "version": version,
                    "name": t,
                }
            )
    return publish


def resolve_git_range(git_range: str) -> Optional[list[str]]:
    """Resolve git range to changed file paths."""
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", git_range],
            capture_output=True,
            text=True,
            check=True,
        )
        return [p for p in result.stdout.strip().split("\n") if p]
    except subprocess.CalledProcessError:
        print(
            f"Warning: git range '{git_range}' unresolvable → build-all fallback",
            file=sys.stderr,
        )
        return None


def _filter_by_pattern(targets: list[str], pattern: str) -> list[str]:
    """Filter target names matching a glob pattern."""
    return [t for t in targets if re.match(pattern.replace("*", ".*"), t)]


def gh_output(name: str, value: str) -> None:
    """Emit GitHub Actions set-output."""
    env_file = os.environ.get("GITHUB_OUTPUT", "")
    if env_file:
        with open(env_file, "a") as f:
            f.write(f"{name}={value}\n")


def select(
    plan: Any,
    changed: Optional[list[str]],
    *,
    build_all: bool = False,
    pattern: Optional[str] = None,
) -> dict[str, Any]:
    """Compute affected build set and publish matrix from plan + changed files.

    Returns dict with keys: all (bool), build (list[str]), publish (list[dict]),
    has_targets ("true"/"false" string for GHA conditional).
    """
    targets = plan.get("target", {})
    if not targets:
        return {"all": True, "build": [], "publish": [], "has_targets": "false"}

    publish_targets = set(plan.get("group", {}).get("publish", {}).get("targets", []))
    if not publish_targets:
        print(
            "Warning: publish group not found in plan — no images will be published",
            file=sys.stderr,
        )

    if changed is not None:
        for path in changed:
            if is_build_all_path(path):
                build_all = True
                break

    if build_all:
        all_targets = sorted(targets.keys())
        if pattern:
            all_targets = _filter_by_pattern(all_targets, pattern)
        publish = partition_publish(targets, all_targets, publish_targets)
        return {
            "all": True,
            "build": all_targets,
            "publish": publish,
            "has_targets": "true" if publish else "false",
        }

    if not changed:
        return {"all": False, "build": [], "publish": [], "has_targets": "false"}

    dir_map = build_dir_map(targets)
    rev_graph = build_reverse_graph(targets)
    extras_map = build_extras_map(targets)

    seeds = changed_files_to_targets(changed, dir_map, extras_map)

    if not seeds:
        return {"all": False, "build": [], "publish": [], "has_targets": "false"}

    build_set = transitive_dependents(seeds, rev_graph)

    if pattern:
        build_set = _filter_by_pattern(build_set, pattern)

    publish = partition_publish(targets, build_set, publish_targets)
    return {
        "all": False,
        "build": build_set,
        "publish": publish,
        "has_targets": "true" if publish else "false",
    }


def matrix_json(publish: list[dict[str, str]]) -> str:
    """Format publish list as GHA matrix include JSON."""
    return json.dumps({"include": publish})


def main() -> int:
    parser = argparse.ArgumentParser(description="bake change-to-matrix selector")
    parser.add_argument("--plan", default="-", help="bake --print JSON plan (default: stdin)")
    parser.add_argument("--changed", nargs="*", default=[], help="changed file paths")
    parser.add_argument("--changed-from", help="read changed paths from file")
    parser.add_argument("--git-range", help="git diff range (e.g. HEAD~1..HEAD)")
    parser.add_argument("--all", action="store_true", help="build all targets")
    parser.add_argument("--pattern", help="glob pattern filter")
    parser.add_argument("--github-output", action="store_true", help="emit GHA set-output")
    args = parser.parse_args()

    plan = load_plan(args.plan)

    changed = list(args.changed) if args.changed else []
    if args.changed_from:
        with open(args.changed_from) as f:
            changed.extend(line.strip() for line in f if line.strip())
    if args.git_range:
        git_changed = resolve_git_range(args.git_range)
        if git_changed is None:
            args.all = True
        else:
            changed.extend(git_changed)

    result = select(
        plan,
        changed if not args.all else None,
        build_all=args.all,
        pattern=args.pattern,
    )

    if args.github_output:
        matrix = matrix_json(result["publish"])
        gh_output("has-targets", result["has_targets"])
        gh_output("matrix", matrix)
        gh_output("build-all", "true" if result["all"] else "false")
    else:
        print(f"all={result['all']}")
        print(f"build={json.dumps(result['build'])}")
        print(f"publish={json.dumps(result['publish'])}")
        print(f"has_targets={result['has_targets']}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
