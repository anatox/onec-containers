"""Точка входа и задачи invoke для утилиты bake."""

# mypy: disable-error-code=arg-type
import json
import shlex
import sys

from invoke.collection import Collection
from invoke.program import Program
from invoke.tasks import task

from .buildx import bake
from .plan import obtain_plan, plan_json
from .select import (
    gh_output,
    matrix_json,
    resolve_git_range,
)
from .select import (
    select as select_run,
)

_extra: list[str] = []


@task(
    help={
        "target": "Целевые образы для сборки через запятую (группы bake тоже допустимы)",
    },
)
def build(c, target: str) -> None:  # type: ignore[no-untyped-def]
    """Сборка указанных образов через docker buildx bake."""
    targets = [t.strip() for t in target.split(",") if t.strip()]
    sys.exit(bake(_extra + targets))


@task(
    help={
        "target": "Имена целевых образов для построения плана (по умолчанию: default publish)",
    },
    iterable=["target"],
)
def plan(c, target: list[str] | None = None) -> None:  # type: ignore[no-untyped-def]
    """Вывод JSON-плана bake в stdout."""
    targets = list(target) if target else None
    print(plan_json(targets), end="")


@task(
    help={
        "git_range": "git diff диапазон (напр. HEAD~1..HEAD)",
        "changed": "Список изменившихся файлов",
        "all": "Собрать все образы",
        "pattern": "Glob-шаблон для фильтрации образов",
        "github_output": "Выводить в формате GitHub Actions output",
    },
    iterable=["changed"],
)
def select(  # type: ignore[no-untyped-def]
    c,
    git_range: str | None = None,
    changed: list[str] | None = None,
    all: bool = False,
    pattern: str | None = None,
    github_output: bool = False,
) -> None:
    """Получение списка целевых образов, затронутых изменениями."""
    text = obtain_plan()
    plan_data = json.loads(text)

    _changed: list[str] = list(changed) if changed else []

    if git_range:
        git_changed = resolve_git_range(git_range)
        if git_changed is None:
            all = True
        else:
            _changed.extend(git_changed)

    result = select_run(
        plan_data,
        _changed if not all else None,
        build_all=all,
        pattern=pattern,
    )

    if github_output:
        matrix = matrix_json(result["publish"])
        gh_output("has-targets", result["has_targets"])
        gh_output("matrix", matrix)
        gh_output("build-all", "true" if result["all"] else "false")
    else:
        print(f"all={result['all']}")
        print(f"build={json.dumps(result['build'])}")
        print(f"publish={json.dumps(result['publish'])}")
        print(f"has_targets={result['has_targets']}")


@task
def lint(c) -> None:  # type: ignore[no-untyped-def]
    """Проверка синтаксиса HCL-файлов (bake --print > /dev/null)."""
    sys.exit(bake(["--print"], ignore_stdout=True))


ns = Collection()
ns.add_task(build)
ns.add_task(lint)
ns.add_task(plan)
ns.add_task(select)


class BakeProgram(Program):
    def execute(self) -> None:
        global _extra
        _extra = shlex.split(self.core.remainder)
        super().execute()


program = BakeProgram(
    namespace=ns,
    version="0.1.0",
)


def main() -> None:
    program.run()
