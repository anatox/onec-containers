"""Селектор «изменения → матрица сборки» для buildx bake.

Читает JSON-план bake, вычисляет цели, требующие пересборки по изменившимся файлам,
и формирует матрицу для GitHub Actions.

Логика отбора:
  1. dirname(dockerfile) → цель для каждого изменившегося файла
  2. description "extra-srcs" → цель для внешних COPY-зависимостей
  3. Обратный граф зависимостей из contexts вида "target:<имя>"
  4. Транзитивное замыкание → итоговый набор сборки
  5. Матрица публикации = набор сборки ∩ группа publish
  6. Пути полной пересборки: bakery/, pyproject.toml, bake, .dockerignore, .github/

Модульные тесты: python3 -m unittest tests/test_bake_select.py
"""

import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Any

GLOBAL_BUILD_ALL = {
    "bakery/",
    "pyproject.toml",
    "bake",
    ".dockerignore",
    ".github/",
}


@dataclass
class Description:
    """Нормализованные селекторные метаданные из поля description цели."""

    image: str
    extra_srcs: list[str] = field(default_factory=list)


def load_plan(text: str) -> Any:
    """Разбирает JSON-план bake в Python-структуру."""
    return json.loads(text)


def build_dir_map(targets: dict[str, Any]) -> dict[str, list[str]]:
    """Строит отображение dirname(dockerfile) → имена целей."""
    dir_map: defaultdict[str, list[str]] = defaultdict(list)
    for name, data in targets.items():
        dockerfile = data.get("dockerfile", "")
        if dockerfile:
            d = os.path.dirname(dockerfile)
            if d:
                dir_map[d].append(name)
    return dict(dir_map)


def build_reverse_graph(targets: dict[str, Any]) -> dict[str, list[str]]:
    """Строит обратный граф зависимостей из contexts вида target:<имя>."""
    rev: defaultdict[str, set[str]] = defaultdict(set)
    for name, data in targets.items():
        contexts = data.get("contexts", {})
        for ctx_val in contexts.values():
            if isinstance(ctx_val, str) and ctx_val.startswith("target:"):
                dep = ctx_val[len("target:") :]
                rev[dep].add(name)
    return {k: sorted(v) for k, v in rev.items()}


def parse_description(data: dict[str, Any]) -> Description | None:
    """Разбирает JSON-поле description цели в Description.

    Возвращает Description(image=..., extra_srcs=[...]) при успехе, или None
    если описание отсутствует, невалидный JSON, не объект или без ключа "image".
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
    """Строит отображение префикс extra-srcs → имена целей."""
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
    """Сопоставляет изменившиеся файлы начальным затронутым целям."""
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
    """Вычисляет транзитивное замыкание зависимых целей от начального набора."""
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
    """Проверяет, является ли путь глобальным триггером полной пересборки."""
    return any(
        path == prefix or (prefix.endswith("/") and path.startswith(prefix))
        for prefix in GLOBAL_BUILD_ALL
    )


def partition_publish(
    targets: dict[str, Any],
    build_set: list[str],
    publish_set: set[str],
) -> list[dict[str, str]]:
    """Фильтрует набор сборки до участников группы publish.

    Возвращает список словарей с ключами target, image, title, version, name
    для матрицы GHA.
    """
    publish = []
    for t in build_set:
        if t in publish_set:
            labels = targets[t].get("labels", {})
            title = labels.get("org.opencontainers.image.title", "")
            version = labels.get("org.opencontainers.image.version", "")
            if not title or not version:
                print(
                    f"ERROR: {t} is in publish group but missing"
                    f" image.title or image.version label",
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


def resolve_git_range(git_range: str) -> list[str] | None:
    """Разрешает git-диапазон в список изменившихся файлов."""
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
    """Фильтрует имена целей по glob-шаблону."""
    return [t for t in targets if re.match(pattern.replace("*", ".*"), t)]


def gh_output(name: str, value: str) -> None:
    """Выводит переменную в GitHub Actions output."""
    env_file = os.environ.get("GITHUB_OUTPUT", "")
    if env_file:
        with open(env_file, "a") as f:
            f.write(f"{name}={value}\n")


def select(
    plan: Any,
    changed: list[str] | None,
    *,
    build_all: bool = False,
    pattern: str | None = None,
) -> dict[str, Any]:
    """Вычисляет набор сборки и матрицу публикации из плана и изменившихся файлов.

    Возвращает словарь с ключами: all, build, publish, has_targets.
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
    """Форматирует список публикаций как JSON include-матрицы GHA."""
    return json.dumps({"include": publish})
