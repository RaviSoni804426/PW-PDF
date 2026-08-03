#!/usr/bin/env python
"""Rebuild only the desktop shell (Qt apps) and redeploy.

The full make.py re-runs the core C++ build from scratch every time, which
costs the better part of an hour. When only desktop-apps sources or resources
changed, this rebuilds those three projects and repeats the deploy step.
"""
import os
import sys

__dir__name__ = os.path.dirname(os.path.abspath(__file__))
sys.path.append(__dir__name__ + '/scripts')
sys.path.append(__dir__name__ + '/scripts/develop')
sys.path.append(__dir__name__ + '/scripts/develop/vendor')
sys.path.append(__dir__name__ + '/scripts/core_common')
sys.path.append(__dir__name__ + '/scripts/core_common/modules')
sys.path.append(__dir__name__ + '/scripts/core_common/modules/android')

import config
import base
import build_sln
import deploy

config.parse()
base.check_python()
base.set_env("BUILD_PLATFORM", config.option("platform"))

print("=== building desktop apps only ===")
build_sln.make("./sln_apps_only.json")

print("=== deploy ===")
deploy.make()
print("=== done ===")
