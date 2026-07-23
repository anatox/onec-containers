#!/usr/bin/env python3
"""Unit tests for bake.select (stdlib unittest, no external deps).

Run with:
  python3 -m unittest tests/test_bake_select.py
  python3 -m unittest discover -s tests -p 'test_*.py'
  pytest tests/test_bake_select.py    # if pytest is available
"""

import contextlib
import importlib.util
import io
import json
import sys
import unittest
from pathlib import Path

_MODULE_PATH = Path(__file__).resolve().parent.parent / "bakery" / "select.py"
_spec = importlib.util.spec_from_file_location("bake_select", _MODULE_PATH)
bake_select = importlib.util.module_from_spec(_spec)
sys.modules["bake_select"] = bake_select
_spec.loader.exec_module(bake_select)

select = bake_select.select


PLAN = {
    "target": {
        "alpha": {
            "dockerfile": "alpha/Dockerfile",
            "contexts": {},
            "labels": {},
            "description": json.dumps({"image": "alpha"}),
        },
        "beta": {
            "dockerfile": "beta/Dockerfile",
            "contexts": {"localhost/alpha:local": "target:alpha"},
            "labels": {
                "org.opencontainers.image.title": "Beta",
                "org.opencontainers.image.version": "1.0",
            },
            "description": json.dumps({"image": "beta"}),
        },
        "gamma": {
            "dockerfile": "gamma/Dockerfile",
            "contexts": {},
            "labels": {
                "org.opencontainers.image.title": "Gamma",
                "org.opencontainers.image.version": "1.0",
            },
            "description": json.dumps({"image": "gamma", "extra-srcs": ["shared/tools"]}),
        },
        "delta": {
            "dockerfile": "delta/Dockerfile",
            "contexts": {
                "localhost/beta:local": "target:beta",
                "localhost/gamma:local": "target:gamma",
            },
            "labels": {
                "org.opencontainers.image.title": "Delta",
                "org.opencontainers.image.version": "1.0",
            },
            "description": json.dumps({"image": "delta"}),
        },
        "standalone": {
            "dockerfile": "standalone/Dockerfile",
            "contexts": {},
            "labels": {
                "org.opencontainers.image.title": "Standalone",
                "org.opencontainers.image.version": "1.0",
            },
            "description": json.dumps({"image": "standalone"}),
        },
        "agent": {
            "dockerfile": "agent/Dockerfile",
            "contexts": {},
            "labels": {},
            "description": json.dumps({"image": "agent"}),
        },
    },
    "group": {
        "publish": {
            "targets": ["beta", "delta", "gamma", "standalone"],
        }
    },
}


class SelectTests(unittest.TestCase):
    def test_empty_changed_yields_no_targets(self):
        r = select(PLAN, [])
        self.assertEqual(r["build"], [])
        self.assertEqual(r["has_targets"], "false")

    def test_unrelated_file_yields_no_targets(self):
        r = select(PLAN, ["README.md"])
        self.assertEqual(r["build"], [])
        self.assertEqual(r["has_targets"], "false")

    def test_standalone_change_yields_standalone_only(self):
        r = select(PLAN, ["standalone/Dockerfile"])
        self.assertEqual(set(r["build"]), {"standalone"})

    def test_skip_publish_target_alone_has_no_publish(self):
        r = select(PLAN, ["agent/Dockerfile"])
        self.assertEqual(r["has_targets"], "false")
        self.assertIn("agent", r["build"])

    def test_alpha_change_yields_transitive_dependents(self):
        r = select(PLAN, ["alpha/Dockerfile"])
        self.assertEqual(set(r["build"]), {"alpha", "beta", "delta"})

    def test_alpha_change_publish_excludes_alpha(self):
        r = select(PLAN, ["alpha/Dockerfile"])
        self.assertEqual(len(r["publish"]), 2)
        self.assertEqual({x["target"] for x in r["publish"]}, {"beta", "delta"})

    def test_beta_change_yields_beta_and_delta(self):
        r = select(PLAN, ["beta/Dockerfile"])
        self.assertEqual(set(r["build"]), {"beta", "delta"})

    def test_gamma_change_yields_gamma_and_delta(self):
        r = select(PLAN, ["gamma/Dockerfile"])
        self.assertEqual(set(r["build"]), {"gamma", "delta"})

    def test_extra_srcs_prefix_maps_to_target(self):
        r = select(PLAN, ["shared/tools/script.sh"])
        self.assertIn("gamma", r["build"])

    def test_bake_dir_change_is_build_all(self):
        r = select(PLAN, ["bakery/versions.hcl"])
        self.assertTrue(r["all"])
        self.assertEqual(len(r["build"]), len(PLAN["target"]))

    def test_build_all_flag_selects_all(self):
        r = select(PLAN, [], build_all=True)
        self.assertTrue(r["all"])
        self.assertEqual(len(r["build"]), len(PLAN["target"]))

    def test_build_all_with_pattern_filters(self):
        r = select(PLAN, [], build_all=True, pattern="a*")
        self.assertEqual(set(r["build"]), {"alpha", "agent"})

    def test_publish_entry_fields(self):
        r = select(PLAN, ["beta/Dockerfile"])
        self.assertEqual(r["publish"][0]["image"], "beta")
        self.assertEqual(r["publish"][0]["title"], "Beta")
        self.assertEqual(r["publish"][0]["version"], "1.0")

    def test_publish_missing_title_raises(self):
        plan = json.loads(json.dumps(PLAN))
        del plan["target"]["beta"]["labels"]["org.opencontainers.image.title"]
        with (
            self.assertRaises(SystemExit) as cm,
            contextlib.redirect_stderr(io.StringIO()),
        ):
            select(plan, ["alpha/Dockerfile"])
        self.assertEqual(cm.exception.code, 1)

    def test_publish_missing_version_raises(self):
        plan = json.loads(json.dumps(PLAN))
        del plan["target"]["beta"]["labels"]["org.opencontainers.image.version"]
        with (
            self.assertRaises(SystemExit) as cm,
            contextlib.redirect_stderr(io.StringIO()),
        ):
            select(plan, ["alpha/Dockerfile"])
        self.assertEqual(cm.exception.code, 1)


if __name__ == "__main__":
    unittest.main()
