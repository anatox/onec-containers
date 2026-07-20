#!/usr/bin/env python3
"""Buildkite-bake change-to-matrix selector. Reads a bake --print JSON plan,
computes which targets need to rebuild from changed file paths, and emits
GitHub Actions matrix output.

Usage:
  scripts/bake-select.py --plan bake-plan.json --changed server/Containerfile
  scripts/bake-select.py --plan bake-plan.json --git-range HEAD~1..HEAD
  scripts/bake-select.py --plan bake-plan.json --all
  scripts/bake-select.py --plan bake-plan.json --all --pattern 'server*'
  scripts/bake-select.py --self-test
"""

import argparse
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

GLOBAL_BUILD_ALL = {
    "bake/",
    "scripts/bake.py",
    ".dockerignore",
    "scripts/bake-select.py",
    ".github/",
}


def load_plan(path):
    if path == "-":
        return json.load(sys.stdin)
    with open(path) as f:
        return json.load(f)


def build_dir_map(targets):
    """Map directory → list of target names using dirname(dockerfile)."""
    dir_map = defaultdict(list)
    for name, data in targets.items():
        dockerfile = data.get("dockerfile", "")
        if dockerfile:
            d = os.path.dirname(dockerfile)
            if d:
                dir_map[d].append(name)
    return dict(dir_map)


def build_reverse_graph(targets):
    """Build reverse dependency graph: dep_target → [consumers].
    Edges come from contexts values of form 'target:<name>'."""
    rev = defaultdict(set)
    for name, data in targets.items():
        contexts = data.get("contexts", {})
        for ctx_val in contexts.values():
            if isinstance(ctx_val, str) and ctx_val.startswith("target:"):
                dep = ctx_val[len("target:"):]
                rev[dep].add(name)
    return {k: sorted(v) for k, v in rev.items()}


def build_extras_map(targets):
    """Map path prefix → list of target names from onec.extra-srcs labels."""
    extras_map = defaultdict(set)
    for name, data in targets.items():
        extras = data.get("labels", {}).get("onec.extra-srcs", "")
        if extras:
            for prefix in extras.split(","):
                prefix = prefix.strip()
                if prefix:
                    extras_map[prefix].add(name)
    return {k: sorted(v) for k, v in extras_map.items()}


def changed_files_to_targets(changed, dir_map, extras_map):
    """Map a set of changed file paths to initial affected targets."""
    targets = set()
    for path in changed:
        path = path.strip()
        if not path:
            continue
        # dirname matching (prefix match)
        parts = path.split("/")
        for depth in range(len(parts)):
            prefix = "/".join(parts[:depth + 1])
            if not prefix:
                continue
            # check dir_map
            if prefix in dir_map:
                targets.update(dir_map[prefix])
            # check extras_map (exact prefix match first, then parent dirs)
            if prefix in extras_map:
                targets.update(extras_map[prefix])
        # also check prefixes in extras_map
        for ep in extras_map:
            if path.startswith(ep.rstrip("/") + "/") or path == ep:
                targets.update(extras_map[ep])
    return targets


def transitive_dependents(seeds, rev_graph):
    """Compute transitive dependents closure from seeds using rev_graph.
    Returns sorted list of all targets in the closure."""
    closure = set(seeds)
    queue = list(seeds)
    while queue:
        node = queue.pop()
        for dep in rev_graph.get(node, []):
            if dep not in closure:
                closure.add(dep)
                queue.append(dep)
    return sorted(closure)


def is_build_all_path(path):
    """Check if a changed path triggers build-all."""
    for prefix in GLOBAL_BUILD_ALL:
        if path == prefix.rstrip("/") or path.startswith(prefix):
            return True
    return False


def partition_publish(targets, build_set):
    """Partition build set into publish matrix: drop skip-publish targets."""
    publish = []
    for t in build_set:
        if targets[t].get("labels", {}).get("onec.skip-publish") != "true":
            image = targets[t].get("labels", {}).get("onec.image", t)
            publish.append({"target": t, "image": image, "name": t})
    return publish


def resolve_git_range(git_range):
    """Resolve git range to changed file paths."""
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", git_range],
            capture_output=True, text=True, check=True
        )
        return [p for p in result.stdout.strip().split("\n") if p]
    except subprocess.CalledProcessError:
        print(f"Warning: git range '{git_range}' unresolvable → build-all fallback",
              file=sys.stderr)
        return None


def gh_output(name, value):
    """Emit GitHub Actions set-output."""
    env_file = os.environ.get("GITHUB_OUTPUT", "")
    if env_file:
        with open(env_file, "a") as f:
            f.write(f"{name}={value}\n")


def select(plan, changed, *, build_all=False, pattern=None):
    """Core selection logic. Returns dict with keys: all, build, publish."""
    targets = plan.get("target", {})
    if not targets:
        return {"all": True, "build": [], "publish": [], "has_targets": "false"}

    # Global paths → build all
    if changed is not None:
        for path in changed:
            if is_build_all_path(path):
                build_all = True
                break

    if build_all:
        all_targets = sorted(targets.keys())
        if pattern:
            all_targets = [t for t in all_targets
                          if re.match(pattern.replace("*", ".*"), t)]
        publish = partition_publish(targets, all_targets)
        return {
            "all": True,
            "build": all_targets,
            "publish": publish,
            "has_targets": "true" if publish else "false",
        }

    if not changed:
        return {"all": False, "build": [], "publish": [], "has_targets": "false"}

    # Build maps
    dir_map = build_dir_map(targets)
    rev_graph = build_reverse_graph(targets)
    extras_map = build_extras_map(targets)

    # Resolve changed files to targets
    seeds = changed_files_to_targets(changed, dir_map, extras_map)

    if not seeds:
        return {"all": False, "build": [], "publish": [], "has_targets": "false"}

    # Transitive dependents
    build_set = transitive_dependents(seeds, rev_graph)

    if pattern:
        build_set = [t for t in build_set
                     if re.match(pattern.replace("*", ".*"), t)]

    publish = partition_publish(targets, build_set)
    return {
        "all": False,
        "build": build_set,
        "publish": publish,
        "has_targets": "true" if publish else "false",
    }


def matrix_json(publish):
    """Format publish list as GHA matrix include JSON."""
    return json.dumps({"include": publish})


# ── Self-test ──

SELF_TEST_PLAN = {
    "target": {
        "alpha": {
            "dockerfile": "alpha/Containerfile",
            "contexts": {},
            "labels": {"onec.image": "alpha", "onec.skip-publish": "true"},
        },
        "beta": {
            "dockerfile": "beta/Containerfile",
            "contexts": {"localhost/alpha:local": "target:alpha"},
            "labels": {"onec.image": "beta"},
        },
        "gamma": {
            "dockerfile": "gamma/Containerfile",
            "contexts": {},
            "labels": {"onec.image": "gamma", "onec.extra-srcs": "shared/tools"},
        },
        "delta": {
            "dockerfile": "delta/Containerfile",
            "contexts": {
                "localhost/beta:local": "target:beta",
                "localhost/gamma:local": "target:gamma",
            },
            "labels": {"onec.image": "delta"},
        },
        "standalone": {
            "dockerfile": "standalone/Containerfile",
            "contexts": {},
            "labels": {"onec.image": "standalone"},
        },
        "agent": {
            "dockerfile": "agent/Containerfile",
            "contexts": {},
            "labels": {"onec.image": "agent", "onec.skip-publish": "true"},
        },
    }
}


def self_test():
    failures = 0
    t = lambda cond, msg: (
        None if cond else (print(f"FAIL: {msg}"), __import__("sys").exit(1) or 1)
    )

    # Test: empty changed → no targets
    r = select(SELF_TEST_PLAN, [])
    t(r["build"] == [] and r["has_targets"] == "false",
      "empty changed should yield no targets")

    # Test: README.md → empty (no matching dir)
    r = select(SELF_TEST_PLAN, ["README.md"])
    t(r["build"] == [] and r["has_targets"] == "false",
      "README.md should yield no targets")

    # Test: standalone change → single target (no dependents)
    r = select(SELF_TEST_PLAN, ["standalone/Containerfile"])
    t(set(r["build"]) == {"standalone"},
      f"standalone change should yield [standalone], got {r['build']}")

    # Test: skip-publish agent → no publish targets
    r = select(SELF_TEST_PLAN, ["agent/Containerfile"])
    t(r["has_targets"] == "false",
      f"skip-publish target alone should give no publish targets, got {r['has_targets']}")
    t("agent" in r["build"],
      f"skip-publish target still in build set, got {r['build']}")

    # Test: pattern filter with build-all
    r = select(SELF_TEST_PLAN, [], build_all=True, pattern="a*")
    t(set(r["build"]) == {"alpha", "agent"},
      f"pattern a* should yield alpha+agent, got {r['build']}")

    # Test: chain: alpha change → alpha+beta+delta (beta dep on alpha, delta on beta)
    r = select(SELF_TEST_PLAN, ["alpha/Containerfile"])
    t(set(r["build"]) == {"alpha", "beta", "delta"},
      f"alpha change should yield alpha+beta+delta, got {r['build']}")

    # Test: skip-publish filtered from publish (alpha is skip-publish, beta+delta published)
    r = select(SELF_TEST_PLAN, ["alpha/Containerfile"])
    t(len(r["publish"]) == 2 and {x["target"] for x in r["publish"]} == {"beta", "delta"},
      f"publish should exclude alpha, got {r['publish']}")

    # Test: fan-in: beta change → beta + delta (not gamma)
    r = select(SELF_TEST_PLAN, ["beta/Containerfile"])
    t(set(r["build"]) == {"beta", "delta"},
      f"beta change should yield beta+delta, got {r['build']}")

    # Test: gamma change → gamma + delta (delta depends on gamma)
    r = select(SELF_TEST_PLAN, ["gamma/Containerfile"])
    t(set(r["build"]) == {"gamma", "delta"},
      f"gamma change should yield gamma+delta, got {r['build']}")

    # Test: extras: shared/tools/x → gamma
    r = select(SELF_TEST_PLAN, ["shared/tools/script.sh"])
    t("gamma" in r["build"],
      f"shared/tools change should include gamma via extras, got {r['build']}")

    # Test: global build-all path
    r = select(SELF_TEST_PLAN, ["bake/versions.hcl"])
    t(r["all"] == True and len(r["build"]) == len(SELF_TEST_PLAN["target"]),
      f"bake/ change should be build-all, got all={r['all']} build={len(r['build'])}")

    # Test: build_all flag
    r = select(SELF_TEST_PLAN, [], build_all=True)
    t(r["all"] == True and len(r["build"]) == len(SELF_TEST_PLAN["target"]),
      "build_all=True should select all")

    # Test: pattern filter
    r = select(SELF_TEST_PLAN, [], build_all=True, pattern="a*")
    t(set(r["build"]) == {"alpha", "agent"},
      f"pattern a* should yield alpha+agent, got {r['build']}")

    # Test: publish has correct image field
    r = select(SELF_TEST_PLAN, ["beta/Containerfile"])
    t(r["publish"][0]["image"] == "beta",
      f"publish image should be onec.image label, got {r['publish'][0]}")

    print(f"OK: all {failures} self-tests passed" if not failures else f"{failures} failures")
    return 0


def main():
    parser = argparse.ArgumentParser(description="bake change-to-matrix selector")
    parser.add_argument("--plan", default="-", help="bake --print JSON plan (default: stdin)")
    parser.add_argument("--changed", nargs="*", default=[], help="changed file paths")
    parser.add_argument("--changed-from", help="read changed paths from file")
    parser.add_argument("--git-range", help="git diff range (e.g. HEAD~1..HEAD)")
    parser.add_argument("--all", action="store_true", help="build all targets")
    parser.add_argument("--pattern", help="glob pattern filter")
    parser.add_argument("--github-output", action="store_true", help="emit GHA set-output")
    parser.add_argument("--self-test", action="store_true", help="run self-tests and exit")
    args = parser.parse_args()

    if args.self_test:
        return self_test()

    plan = load_plan(args.plan)

    # Collect changed paths
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

    result = select(plan, changed if not args.all else None,
                    build_all=args.all, pattern=args.pattern)

    # Output
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
