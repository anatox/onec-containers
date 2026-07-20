#!/usr/bin/env python3
"""Top-level launcher for the bake change-to-matrix selector — delegates to bake.select."""

import subprocess
import sys

cmd = [sys.executable, "-m", "bake.select"] + sys.argv[1:]
sys.exit(subprocess.run(cmd).returncode)
