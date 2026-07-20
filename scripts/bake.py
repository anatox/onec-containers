#!/usr/bin/env python3
"""Wrapper for docker buildx bake with automatic HCL discovery.

Scans bake/*.hcl and */bake.hcl, passes them as explicit -f flags
to avoid bake compose.yaml auto-discovery pitfall.
"""

import glob
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

shared = sorted(glob.glob(str(ROOT / "bake" / "*.hcl")))
local = sorted(glob.glob(str(ROOT / "*" / "bake.hcl")))

all_files = shared + local

cmd = ["docker", "buildx", "bake"] + [flag for f in all_files for flag in ("-f", f)] + sys.argv[1:]
sys.exit(subprocess.run(cmd).returncode)
