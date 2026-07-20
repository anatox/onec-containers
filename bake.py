#!/usr/bin/env python3
"""Top-level launcher for docker buildx bake — delegates to bake.cli."""

import subprocess
import sys
from pathlib import Path

cmd = [sys.executable, "-m", "bake.cli"] + sys.argv[1:]
sys.exit(subprocess.run(cmd).returncode)
