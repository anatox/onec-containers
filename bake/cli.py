#!/usr/bin/env python3
"""Wrapper for docker buildx bake with automatic HCL discovery.

Scans bake/*.hcl and */bake.hcl, passes them as explicit -f flags
to avoid bake compose.yaml auto-discovery pitfall.

Re-emits Github Actions workflow commands without BuildKit prefixes.
"""

import codecs
import glob
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import NoReturn

ROOT = Path(__file__).resolve().parent.parent

shared = sorted(glob.glob(str(ROOT / "bake" / "*.hcl")))
local = sorted(glob.glob(str(ROOT / "*" / "bake.hcl")))

all_files = shared + local

ANSI = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
WORKFLOW_CMD = re.compile(r"^(?:#\d+\s+)?\d+(?:\.\d+)?\s+(::(?:error|warning|notice)\b.*)$")


def main() -> None:
    cmd = ["docker", "buildx", "bake"]

    is_print = any(a == "--print" for a in sys.argv[1:])
    in_actions = os.environ.get("GITHUB_ACTIONS") == "true"

    if not in_actions or is_print:
        cmd += [flag for f in all_files for flag in ("-f", f)]
        cmd += sys.argv[1:]
        sys.exit(subprocess.run(cmd).returncode)

    if not any(a.startswith("--progress") for a in sys.argv[1:]):
        cmd.append("--progress=plain")
    cmd += [flag for f in all_files for flag in ("-f", f)]
    cmd += sys.argv[1:]

    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        bufsize=0,  # raw, unbuffered
    )

    raw_out = sys.stdout.buffer
    decoder = codecs.getincrementaldecoder("utf-8")(errors="replace")
    pending = ""
    seen: set[str] = set()

    def scan(line: str) -> None:
        m = WORKFLOW_CMD.match(ANSI.sub("", line).strip())
        if m and m.group(1) not in seen:
            seen.add(m.group(1))
            raw_out.write((m.group(1) + "\n").encode("utf-8"))
            raw_out.flush()

    stdout = proc.stdout
    assert stdout is not None
    while True:
        chunk = stdout.read(65536)
        if not chunk:
            break

        raw_out.write(chunk)
        raw_out.flush()

        pending += decoder.decode(chunk)
        while True:
            idx = min(
                (i for i in (pending.find("\n"), pending.find("\r")) if i >= 0),
                default=-1,
            )
            if idx < 0:
                break
            scan(pending[:idx])
            pending = pending[idx + 1 :]

    if pending:
        scan(pending)

    sys.exit(proc.wait())


if __name__ == "__main__":
    main()
