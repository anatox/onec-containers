"""Получение и загрузка JSON-плана bake."""

import subprocess
import sys
from typing import cast

from .buildx import bake


def plan_json(targets: list[str] | None = None) -> str:
    """Запускает docker buildx bake --print с указанными образами, возвращает stdout."""
    if targets is None:
        targets = ["default", "publish"]
    try:
        result = bake(["--print"] + targets, capture_stdout=True)
    except subprocess.CalledProcessError as e:
        print(
            f"ОШИБКА: docker buildx bake --print завершился с кодом {e.returncode}",
            file=sys.stderr,
        )
        sys.exit(e.returncode or 1)
    return cast(subprocess.CompletedProcess[str], result).stdout


def stdin_plan() -> str | None:
    """Читает план из stdin, если он подключен и непуст.

    Возвращает текст плана, или None если stdin — терминал или пуст.
    """
    if sys.stdin.isatty():
        return None
    data = sys.stdin.read()
    if not data.strip():
        return None
    return data


def obtain_plan(targets: list[str] | None = None) -> str:
    """Возвращает текст плана: из stdin (если есть) или запуском buildx --print."""
    from_stdin = stdin_plan()
    if from_stdin is not None:
        return from_stdin
    return plan_json(targets)
