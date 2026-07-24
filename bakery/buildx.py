"""Обёртка docker buildx bake — сборка командной строки, запуск, препроцессинг."""

import glob
import io
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

ANSI = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
WORKFLOW_CMD = re.compile(r"^(?:#\d+\s+)?\d+(?:\.\d+)?\s+(::(?:error|warning|notice)\b.*)$")


def discover_hcl_files() -> list[str]:
    """Возвращает отсортированный список всех HCL-файлов bake (общие + локальные)."""
    shared = sorted(glob.glob(str(ROOT / "bakery" / "*.hcl")))
    local = sorted(glob.glob(str(ROOT / "*" / "bake.hcl")))
    return shared + local


def buildx_args(
    extra: list[str] | None = None,
    *,
    hcl_files: list[str] | None = None,
    print_only: bool = False,
    progress_plain: bool = False,
    target: str | None = None,
) -> list[str]:
    """Собирает командную строку docker buildx bake."""
    if hcl_files is None:
        hcl_files = discover_hcl_files()
    cmd: list[str] = ["docker", "buildx", "bake"]
    if print_only:
        cmd.append("--print")
    elif progress_plain:
        cmd.append("--progress=plain")
    for f in hcl_files:
        cmd += ["-f", f]
    if target:
        cmd.append(target)
    if extra:
        cmd.extend(extra)
    return cmd


def _workflow_command(line: str) -> str | None:
    """Извлекает workflow-команду GitHub Actions из очищенной строки.

    Возвращает строку команды (например, «::error file=foo::msg») или None.
    """
    m = WORKFLOW_CMD.match(ANSI.sub("", line).strip())
    if m:
        return m.group(1)
    return None


def _run_reemitting(cmd: list[str]) -> int:
    """Запускает команду с препроцессингом stdout.
    
    Удаляет префиксы Buildx для корректной работы команд GitHub Actions.
    Дубликаты команд подавляются. Возвращает код возврата процесса.
    """
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=ROOT,
    )
    seen: set[str] = set()
    assert proc.stdout is not None
    # newline="" — readline режет по \n/\r/\r\n, концы строк проходят как есть
    stdout = io.TextIOWrapper(proc.stdout, encoding="utf-8", errors="replace", newline="")
    for line in stdout:
        sys.stdout.write(line)
        cmd_line = _workflow_command(line)
        if cmd_line and cmd_line not in seen:
            seen.add(cmd_line)
            if not line.endswith(("\r", "\n")):  # незавершённая последняя строка
                sys.stdout.write("\n")
            sys.stdout.write(cmd_line + "\n")
        sys.stdout.flush()
    return proc.wait()


def _run(cmd: list[str], stdout: int | None = None) -> int:
    """Запускает команду, возвращает код возврата."""
    return subprocess.run(cmd, stdout=stdout, cwd=ROOT).returncode


def bake(
    args: list[str],
    *,
    in_actions: bool | None = None,
    capture_stdout: bool = False,
    ignore_stdout: bool = False,
) -> int | subprocess.CompletedProcess[str]:
    """Выполняет docker buildx bake.

    Без capture_stdout: напрямую или с препроцессингом workflow-команд GitHub Actions
    (если GITHUB_ACTIONS=true и не --print). С capture_stdout=True: захватывает stdout,
    stderr проходит напрямую. С ignore_stdout=True: stdout направляется в /dev/null.
    """
    if in_actions is None:
        in_actions = os.environ.get("GITHUB_ACTIONS") == "true"
    cmd = buildx_args(args, progress_plain=(in_actions and not any(a == "--print" for a in args)))
    if capture_stdout:
        return subprocess.run(cmd, stdout=subprocess.PIPE, text=True, cwd=ROOT, check=True)
    if ignore_stdout:
        return _run(cmd, stdout=subprocess.DEVNULL)
    if not in_actions or "--print" in args:
        return _run(cmd)
    return _run_reemitting(cmd)
